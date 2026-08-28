# Demo sandbox

Open [the demo](https://accessible-explanation-checkin.sociobot.in/demo) or `/?demo=1` to enter a populated teacher review. It contains a watershed prompt and three student explanations.

The demo stores review edits only in the browser under the `demo:accessible-explanation-checkin:review` localStorage key. It makes no API requests and never reads or writes normal check-in storage. **Reset demo** removes that key and restores the shipped sample. **Start for real** opens the separate check-in creation flow.

After the first visit, the service worker caches the demo shell so `/demo` reloads while offline. The claim tests use this URL from a fresh context.
