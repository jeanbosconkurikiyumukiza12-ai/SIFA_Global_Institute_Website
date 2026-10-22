# SIFA reachability and slow-internet diagnostics

## What was improved in this local build

- Re-encoded the founder and Joseph profile photos and SIFA logo as WebP, with appropriate display dimensions.
- Re-encoded the five homepage feature photos as WebP.
- Updated local HTML/CSS/JS/text references to the new image filenames.
- Kept the original image files in the archive as a fallback/reference; the pages now request the smaller WebP versions.

These changes reduce the size of images requested by the site. They do not, by themselves, fix a hosting outage, DNS problem, Wi-Fi/ISP issue, or a stopped local Live Server.

## Test the local VS Code/Live Server site

1. Open the extracted project folder in VS Code.
2. Start Live Server from `index.html`.
3. Keep VS Code open while testing; Live Server runs on your computer and stops if the server/process stops.
4. Confirm the address starts with `http://127.0.0.1:5500/` (or the port Live Server shows). `127.0.0.1` is only accessible on the same computer; students cannot use your local address.
5. If it fails, check the Live Server status in VS Code and click **Go Live** again. If the port is different, use the new URL. Avoid opening a stale local tab after stopping/restarting Live Server.

## Test the published Vercel site

1. Open `https://sifaglobalinstitutewebsite.vercel.app/` in a private window.
2. If it fails, try the same URL using mobile data instead of Wi-Fi.
3. On Windows, open Command Prompt and run:
   - `nslookup sifaglobalinstitutewebsite.vercel.app`
   - `curl -I https://sifaglobalinstitutewebsite.vercel.app/`
4. Record the exact error and time. If `nslookup` fails, investigate DNS/network. If DNS succeeds but `curl` reports a connection/TLS/HTTP error, investigate the network route or Vercel deployment/edge response. A successful HTTP response with a broken page requires browser DevTools Console/Network checks.
5. Check the Vercel deployment status and deployment logs for the matching time. Do not redeploy or change DNS until the evidence points there.

## How to distinguish the two symptoms

- `127.0.0.1` / `localhost` fails: usually Live Server is stopped, the port changed, or the browser is using a stale local URL. This is not caused by the public site's internet weight.
- Public Vercel URL fails intermittently: possible local Wi-Fi/ISP/DNS/routing issue or hosting/CDN issue. Compare Wi-Fi vs mobile data and run the commands above.
- Site opens but takes a long time to display: use browser DevTools > Network, disable cache, reload, sort by Size and Time. Large image transfers are a performance issue; failed document requests or connection errors are a reachability issue.

## Limitations

This package has not been deployed. No live Vercel logs, user's Wi-Fi/DNS, or user's local Live Server process are accessible from this build. Therefore it would be misleading to claim the intermittent `ERR_CONNECTION_CLOSED` / "This site can't be reached" symptom is solved until the live and local checks above pass repeatedly.
