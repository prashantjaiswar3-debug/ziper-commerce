# ZIPER Storefront — Supabase connected starter

Premium black / beige / gold storefront for ZIPER footwear and accessories. The static storefront uses the Supabase **publishable** key in browser code and supports customer email/password accounts, live catalogue reads, COD orders, stock deduction in a single database transaction, and a role-protected admin dashboard.

## Supabase project

- Project URL: `https://qaomkonssxqkeowalxxi.supabase.co`
- Region: Mumbai (`ap-south-1`)
- The browser uses a Supabase publishable key in `ziper_website/config.js`. Publishable keys are designed for public clients and rely on Row Level Security.
- **Never put a Supabase secret or legacy `service_role` key in this repository, frontend files, GitHub Actions YAML, or browser code.** If a privileged backend is added later, store its key only in server-side secret storage.

## Run locally

Serve the website folder with a static web server (do not open `index.html` as a `file://` URL):

```bash
cd ziper_website
python -m http.server 8080
```

Then visit `http://localhost:8080`.

## First-time setup

1. In Supabase Authentication, configure email sign-up and your production Site URL / redirect URLs.
2. Create a customer account from the storefront and confirm its email if confirmation is enabled.
3. To grant the first store administrator, run this SQL in the Supabase SQL Editor only after the intended email has signed up and been verified:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id and lower(u.email) = lower('YOUR_VERIFIED_ADMIN_EMAIL');
```

4. Sign out and back in; the Admin dashboard link will appear. Add products with their correct selling price, image path/URL, sizes and stock. Example image paths are `assets/ziper-footwear.png` and `assets/ziper-accessories.png`.
5. Before launch, decide the delivery fee and update `public.store_settings` row `key='checkout'` (`shipping_fee_paise` is in paise; 100 paise = ₹1). Current value is ₹0 as a temporary free-delivery default.
6. Update the customer support email, shipping/returns policy, privacy policy, terms, and brand copy before public launch.

## COD checkout

- Online payments are disabled. `payment_method` is constrained to `cod`.
- The browser sends only variant IDs and quantities. The database calculates prices, shipping and totals from stored records.
- `place_cod_order` requires a signed-in user, checks active products/variants and available stock, creates the order and order items, and deducts stock atomically.
- Order payment status remains `pending` until COD is collected. Admins can update fulfilment status in the dashboard.

## GitHub Pages deployment

The workflow at `.github/workflows/pages.yml` publishes the contents of `ziper_website/` directly to GitHub Pages whenever a commit is pushed to `main`, and also supports manual runs.

1. Open this repository's **Settings → Pages**.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Open the **Actions** tab and check the **Deploy ZIPER to GitHub Pages** workflow. A successful run publishes the site at `https://prashantjaiswar3-debug.github.io/ziper-commerce/`.
4. Add that production URL to Supabase Auth's allowed Site URL and redirect URLs.

The workflow does not need a Supabase secret: the static storefront only uses the public publishable key. Do not add service-role/secret keys as GitHub repository variables or Actions secrets for this static deployment.

## Security incident response

If a legacy `service_role` key or a Supabase secret key was ever committed or otherwise exposed, treat it as compromised even after deleting it from the latest source. Rotate/retire it in **Supabase Dashboard → Project Settings → API Keys** using Supabase's current rotation procedure, and review project logs for unexpected privileged activity. If the exposed value was the legacy `service_role` JWT, follow Supabase's instructions for migrating away from legacy keys and revoking the compromised key/JWT signing secret. Do not paste the key into chat or commit its replacement.

## Important scope notes

- The supplied product photographs are visual assets. Product names/prices/stock are not invented or preloaded; add the actual catalogue through Admin.
- Customer email/password auth is used. Configure SMTP/email confirmation in Supabase before accepting customers.
- Admin role must be granted securely by the project owner; public sign-up cannot self-assign admin.
- Test checkout with a test product and small stock count before public launch. Review tax, shipping, consumer-law, privacy, and returns obligations for your business.
