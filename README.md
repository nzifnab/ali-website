## Google API Setup

- Go to the google credentials console at: https://console.developers.google.com/apis/credentials
- Set up a new project (top-left dropdown, "Select a project", create a new one)
- With the project selected, go to the "Credentials" section
- Create an API Key and a Service Account
- Copy the API Key and set the environment variable `GOOGLE_API_KEY` to it (IE: `heroku config set GOOGLE_API_KEY='YOUR_API_KEY'`)
- Go to "Manage Service Accounts" and create a new one
- Next to the listed service account under "Actions" select "Create Key"; download the json file and open it in notepad (or other simple text editor).
- Set an environment variable `GOOGLE_ACCOUNT_TYPE` to the listed type in the json file (likely `service_account`)
- Set an environment variable `GOOGLE_CLIENT_EMAIL` to the `client_email` value listed in the json file.
- Set an environment variable `GOOGLE_PRIVATE_KEY` to the `private_key` listed in the json file (this one is long)
- Set an environment variable `MARKET_SHEET_ID` to the google sheet that contains market data. This is the tokenized id you can find in the URL, but _not the entire url itself_
- Make sure to share the market sheet with the service account's email that you set for `GOOGLE_CLIENT_EMAIL`

## On the market sheet you need to set some named ranges. This is so that added/removed rows will not affect functionality of the website.:

- ~"ItemNames": This should be the entire list of item names on the google sheet, EXCLUDING the header row. As of the time of writing this, it is "PurchasePrices!D2:D1000"~ (no longer necessary as the app no longer tries to push updates to the non-public `PurchasePrices` sheet).
- "ItemNamesPublic": This is the list of item names on the _public_ prices sheet, which is a filtered version of the other list. Do not include header row.
- ~"ItemStock": This is the current stock value from the non-public sheet. This is the range that the website will UPDATE when orders are completed. Do not include header row.~ No longer necessary, app no longer pushes updates to this sheet.
- "PurchaseWebsiteData": This is basically the entire PurchasePricesPublic table, including the header rows ("PurchasePricesPublic!A1:I945")
