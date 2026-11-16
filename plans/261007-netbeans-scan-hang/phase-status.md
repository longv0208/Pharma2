# NetBeans scan hang - 2026-10-07

- Cause confirmed from repeated Java thread dumps: ProxyAutoConfig waits for
  its own PAC initialization while XML schema parsing waits on the same PAC;
  RepositoryUpdater cannot finish, and the Pharma_Flow Run target waits for it.
- apiguardian-api-1.1.2.jar can be read by the JDK jar tool.
- Direct HTTPS access to the Jakarta Servlet 6.0 schema: HTTP 200.
- NetBeans user preference proxyType=0 (No Proxy) applied with backup.
- Save All and Exit IDE performed before stopping the remaining stuck JVM.
- Original NetBeans user profile restarted successfully. Project indexing
  completed, including Pharma_Flow src/java; no scan is pending.
- NetBeans Clean and Build (Shift+F11): BUILD SUCCESSFUL, 13 seconds.
- Tomcat /Pharma_Flow context is running from the current project build/web.
- Home, products, and sign-in pages: HTTP 200 before Clean and Build.
  The catalog contained a real active product from pharmaflow.
- Tomcat Manager login with the configured local sa account: HTTP 200.
- Configuration backup and diagnostic thread dump:
  C:\Users\PC-DELL\AppData\Local\PharmaFlow\netbeans-fix-20261007\
- Pending: user completes the Tomcat Manager authentication dialog, then
  verify Run Project (F6) and the database-backed pages after deployment.