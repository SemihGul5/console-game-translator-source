# Samsung Tizen receiver

This is a Tizen Web app, not an Android APK. After setup, check that HDMI gameplay and the sample subtitle are visible together. Having trouble? Send your TV model, a description and a screenshot to abrebostudio@gmail.com so we can help.

## First installation from a computer

1. Install Tizen Studio, TV Extensions and Samsung Certificate Extension:
   https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/installing-tv-sdk.html
2. Put the TV and computer on the same LAN. Open Apps on the TV, enter `12345`,
   enable Developer Mode and enter the **computer's IPv4**, then restart the TV.
   https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/tv-device.html
3. Create a Samsung **TV** certificate profile in Certificate Manager, including
   the TV DUID. Connect through Device Manager and select "Permit to install
   applications". Keep your signing keys private and retain them for updates.
   https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html
4. Extract this archive and build/sign with your certificate profile:

   ```powershell
   .\package.ps1 -CertificateProfile 'YourProfile' -TizenCli 'C:\tizen-studio\tools\ide\bin\tizen.bat'
   ```

5. Install the generated `.wgt` using Tizen Studio or its CLI. Substitute the
   actual filename from `output` and the TV serial from `sdb devices`:

   ```powershell
   C:\tizen-studio\tools\sdb.exe devices
   C:\tizen-studio\tools\ide\bin\tizen.bat install -s TV_SERIAL -n Receiver.wgt -- .\output
   C:\tizen-studio\tools\ide\bin\tizen.bat run -s TV_SERIAL -p CGTransTV1.Receiver
   ```

   https://developer.samsung.com/smarttv/develop/getting-started/using-sdk/command-line-interface.html

Ordinary `.wgt` files cannot be installed from USB on consumer Samsung TVs.

## Each session

On the phone, select Samsung Tizen and open a local session. Enter the **phone's
IPv4:port address** and six-digit PIN in the TV receiver. PINs expire in two minutes
and lock after five failures. A successful pairing consumes the PIN. Reconnection
uses a random token stored in memory only; closing either app requires new pairing.

Choose the PS5 HDMI input, test HDMI + sample subtitles and confirm **only when
gameplay and text are both visible**. Keep the receiver open. Home or changing
input interrupts subtitles; another test is required after reconnecting. Back
opens settings. No TV screen capture occurs: OCR uses PS5 Remote Play on the phone.

Use a trusted home LAN. This mode sends subtitle text and styling without
encryption; PSN/Google credentials and video are never sent. Do not forward ports.

Check HDMI audio, multiple subtitle regions, styling, stop/clear, network loss,
phone screen off, restarts and a 30-minute session on your TV. Compare game mode,
HDR, VRR, 4K/120Hz and latency: TVWindow support does not guarantee their retention.

TVWindow API:
https://developer.samsung.com/smarttv/develop/api-references/tizen-web-device-api-references/tvwindow-api.html
