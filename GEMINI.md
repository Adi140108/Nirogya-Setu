# Repository Rules & Guidelines

## Web Application Parity & Auto-Deployment Rule
Whenever you make any changes to the application:
1. **Viewport & Responsiveness Parity**: Ensure that UI elements, text, and cards are tested and responsive across both mobile form factors and web viewports, preventing any RenderFlex or pixel overflow.
2. **Build Web Release**: Compile the Flutter web bundle using `flutter build web --release`.
3. **Deploy Web App**: Deploy the updated web build to Firebase Hosting via `cmd.exe /c "npx --yes firebase-tools deploy --only hosting"`.
4. **Git Commits & Push**: Do NOT commit or push to Git until the user explicitly asks you to.
