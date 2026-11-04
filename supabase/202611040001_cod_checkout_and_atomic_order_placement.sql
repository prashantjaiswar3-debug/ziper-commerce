-- ZIPER COD checkout. Prices, stock and shipping are calculated in Postgres,
-- never trusted from the browser. Execute as a Supabase migration.
alter table public.orders
  add column if not exists payment_method text not null default 'cod';
alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check check (payment_method = 'cod');
alter table public.orders alter column payment_provider set default 'cod';

create or replace function public.place_cod_order(
  p_customer_name text,
  p_customer_phone text,
  p_customer_email text,
  p_shipping_address jsonb,
  p_items jsonb,
  p_customer_note text default null
)
returns table(order_id uuid, order_number text, total_paise integer)
language plpgsql security definer set search_path = '' as $$
declare
  v_user_id uuid := auth.uid(); v_order_id uuid; v_order_number text;
  v_subtotal integer := 0; v_shipping integer := 0; v_total integer := 0;
  v_item jsonb; v_variant record; v_qty integer;
begin
  if v_user_id is null then raise exception 'Please sign in before placing an order'; end if;
  if length(trim(coalesce(p_customer_name,''))) < 2
     or length(regexp_replace(coalesce(p_customer_phone,''), '\D', '', 'g')) < 10
     or p_shipping_address is null or jsonb_typeof(p_shipping_address) <> 'object'
     or p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Please provide valid customer, delivery and item details';
  end if;
  if jsonb_array_length(p_items) > 30 then raise exception 'Too many different items in one order'; end if;
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    if v_qty < 1 or v_qty > 10 then raise exception 'Invalid item quantity'; end if;
    select pv.id as variant_id, pv.product_id, pv.size_label, pv.color, pv.sku,
           pv.stock_quantity, p.name, p.price_paise into v_variant
      from public.product_variants pv join public.products p on p.id=pv.product_id
     where pv.id=(v_item->>'variant_id')::uuid and pv.is_active=true and p.is_active=true
     for update of pv;
    if not found then raise exception 'One of the selected products is unavailable'; end if;
    if v_variant.stock_quantity < v_qty then raise exception 'Insufficient stock for %',v_variant.name; end if;
    v_subtotal := v_subtotal + v_variant.price_paise*v_qty;
  end loop;
  select coalesce((value->>'shipping_fee_paise')::integer,0) into v_shipping
    from public.store_settings where key='checkout';
  v_shipping := greatest(coalesce(v_shipping,0),0); v_total := v_subtotal+v_shipping;
  insert into public.orders(user_id,customer_name,customer_email,customer_phone,shipping_address,
    subtotal_paise,shipping_paise,discount_paise,total_paise,payment_method,payment_provider,
    payment_status,order_status,customer_note)
  values(v_user_id,trim(p_customer_name),nullif(trim(coalesce(p_customer_email,'')),''),
    trim(p_customer_phone),p_shipping_address,v_subtotal,v_shipping,0,v_total,'cod','cod',
    'pending','placed',nullif(trim(coalesce(p_customer_note,'')),''))
  returning id,orders.order_number into v_order_id,v_order_number;
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    select pv.id as variant_id,pv.product_id,pv.size_label,pv.color,pv.sku,pv.stock_quantity,
           p.name,p.price_paise into v_variant
      from public.product_variants pv join public.products p on p.id=pv.product_id
     where pv.id=(v_item->>'variant_id')::uuid and pv.is_active=true and p.is_active=true
     for update of pv;
    insert into public.order_items(order_id,product_id,variant_id,product_name,sku,size_label,color,
      unit_price_paise,quantity,line_total_paise)
    values(v_order_id,v_variant.product_id,v_variant.variant_id,v_variant.name,v_variant.sku,
      v_variant.size_label,v_variant.color,v_variant.price_paise,v_qty,v_variant.price_paise*v_qty);
    update public.product_variants set stock_quantity=stock_quantity-v_qty where id=v_variant.variant_id;
  end loop;
  return query select v_order_id,v_order_number,v_total;
end; $$;
revoke all on function public.place_cod_order(text,text,text,jsonb,jsonb,text) from public,anon;
grant execute on function public.place_cod_order(text,text,text,jsonb,jsonb,text) to authenticated;
