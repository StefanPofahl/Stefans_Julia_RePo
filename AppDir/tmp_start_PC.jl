print("\033]0;v1.6.7, App: MyAppReadToml, env: AppDir/MyAppReadToml\007")
cd(raw"/media/stefan/DATA/repos/own_repos/Stefans_Julia_RePo/AppDir")
using PackageCompiler
create_app("MyAppReadToml", "tmp_MyAppReadToml_compiled_j1.6.7_PCv2.1.5"; force=true, include_lazy_artifacts=true)
