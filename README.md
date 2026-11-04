# ZIPER Storefront — Supabase connected starter

Premium black / beige / gold storefront for ZIPER footwear and accessories. This project is wired to the existing Supabase project and supports customer email/password accounts, live catalogue reads, COD orders, stock deduction in a single database transaction, and a role-protected admin dashboard.

## Supabase project
- URL: `https://qaomkonssxqkeowalxxi.supabase.co`
- Region: Mumbai (`ap-south-1`)
- Public publishable key is in `config.js`. It is intended for browser use. Never add a Supabase secret/service-role key to this repository.

## Run locally
Serve this folder with any static web server (do not open `index.html` as a `file://` URL). Example:

```bash
python -m http.server 8080
```

Then visit `http://localhost:8080`.

## First-time setup
1. In Supabase Authentication, configure email sign-up and your production Site URL / redirect URLs.
2. Create a customer account from the storefront and confirm its email if confirmation is enabled.
3. To grant the first store administrator, run this SQL in the Supabase SQL Editor after replacing the email with the exact verified admin email:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id and lower(u.email) = lower('YOUR_VERIFIED_ADMIN_EMAIL');
```

4. Sign out and back in; the Admin dashboard link will appear. Add products with their correct selling price, image path/URL, sizes and stock. Example image paths for the supplied ZIPER photos are `assets/ziper-footwear.png` and `assets/ziper-accessories.png`.
5. Before launch, decide the delivery fee and update `public.store_settings` row `key='checkout'` (`shipping_fee_paise` is in paise; 100 paise = ₹1). Current value is ₹0 as a temporary free-delivery default.
6. Update the customer support email, shipping/returns policy, privacy policy, terms, and brand copy before public launch.

## COD checkout
- Online payments are disabled. `payment_method` is constrained to `cod`.
- The browser sends only variant IDs and quantities. The database calculates prices, shipping and totals from stored records.
- `place_cod_order` requires a signed-in user, checks active products/variants and available stock, creates the order and order items, and deducts stock atomically.
- Order payment status remains `pending` until COD is collected. Admins can update fulfilment status in the dashboard.

## Deployment
This is a static website and can be hosted on GitHub Pages, Netlify, Vercel or another static host. Set the production URL in Supabase Auth redirect settings. The GitHub repository and hosting project are not created by this package; connect this folder to a new repository and deploy it from your hosting account.

## Important scope notes
- The two supplied product photographs are used as the visual assets. Product names/prices/stock are not invented or preloaded; add the actual catalogue through Admin.
- Customer email/password auth is used. Configure SMTP/email confirmation in Supabase before accepting customers.
- Admin role must be granted securely by the project owner; public sign-up cannot self-assign admin.
- Test checkout with a test product and small stock count before public launch. Review tax, shipping, consumer-law, privacy, and returns obligations for your business.
