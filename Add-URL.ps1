# Carlos Perez provided this bit of code to help with ignoring the self-signed
# certificate on Nessus. If you are not using a self-signed certificate you
# don't need this bit of code.
if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne 'IgnoreCerts')
{
    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
    $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
    $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
    $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | % {$_.ParameterType})))
    $ILGen = $MethodBuilder.GetILGenerator()
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
    $TypeBuilder.CreateType() | Out-Null

    # Disable SSL certificate validation
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
}

##Firewall URL
$HostPA = "https://x.x.x.x"

##API Key
$apiKey = "your_api_key"

##Name for custom URL Category
$category = "your_category"

## input file, one url per line, formated like this:  <member>somesite.com</member>
$urls = (Get-Content .\urls.xml) -join""


##Send new list, replaces all items within the category
[xml]$content = Invoke-RestMethod "$HostPA/api/?xpath=/config/devices/entry/vsys/entry/profiles/custom-url-category/entry[@name='$category']/list&action=edit&type=config&element=<list>$urls</list>&key=$apiKey"

##Print response code
$content.response

##Commit Changes
[xml]$content = Invoke-RestMethod "$HostPA/api/?type=commit&cmd=<commit></commit>&key=$apiKey"

##Print response code
$content.response
