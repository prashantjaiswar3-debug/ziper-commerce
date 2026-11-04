# ZIPER Storefront — Supabase connected

Premium black / beige / gold storefront for ZIPER footwear and accessories.

## Stack
- Static HTML, CSS and JavaScript
- Supabase Auth and Postgres
- Cash on Delivery (COD) checkout
- Server-side order and stock validation through the `place_cod_order` RPC

## Supabase
- Project URL: `https://qaomkonssxqkeowalxxi.supabase.co`
- Region: Mumbai (`ap-south-1`)
- Browser configuration is in `config.js`; it contains only the public publishable key.
- Never commit a Supabase service-role key or other secret.

## Run locally
Serve this directory with a static web server; do not open the page as a `file://` URL.

```bash
python -m http.server 8080
```

Open `http://localhost:8080`.

## First-time setup
1. In Supabase Authentication, configure the Site URL and allowed redirect URLs for your eventual website domain.
2. Configure email delivery/SMTP and test customer sign-up and email confirmation.
3. Create a customer account and verify the email.
4. To grant the first store administrator, run this SQL in the Supabase SQL Editor with the exact verified email:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('YOUR_VERIFIED_ADMIN_EMAIL');
```

5. Sign out and back in. The Admin dashboard link will appear. Add real products, prices, variants and stock through Admin.
6. Confirm the delivery fee. The current checkout setting is free delivery (₹0) as a temporary default.
7. Add customer support details and publish shipping, returns, privacy and terms policies before launch.

## COD checkout
- Online payments are disabled; COD is the only configured payment method.
- The browser submits variant IDs and quantities. The database calculates prices, shipping and totals.
- The `place_cod_order` function checks the signed-in user, product availability and stock, creates the order and order items, and deducts stock atomically.
- Payment remains pending until COD is collected.

## GitHub Pages
The repository is being prepared for GitHub Pages. Once files are committed:
1. Open repository Settings → Pages.
2. Under Build and deployment, select Deploy from a branch.
3. Select branch `main` and folder `/(root)`, then Save.
4. After GitHub publishes the site, copy its URL into Supabase Authentication → URL Configuration → Site URL and Redirect URLs.

## Before launch
- Add real catalogue data and test a complete COD order.
- Configure production email/redirect settings.
- Confirm shipping fees, tax treatment, consumer-law requirements, support contact and policies.
- Never expose a service-role key in browser code.
