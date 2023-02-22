run(`cmd /C 'title '"MyAppHelloTulip_j1.6.7_PCv2.1.5"`)
cd(raw"c:\data\git_repos\own_repos\Stefans_Julia_RePo\AppDir")
using PackageCompiler
create_app("MyAppHelloTulip", "MyAppHelloTulip_j1.6.7_PCv2.1.5"; force=true, include_lazy_artifacts=true)
