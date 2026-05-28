Add-Type -AssemblyName PresentationFramework

$xamlFile = "C:\Users\Admin\Documents\PowerShell Scripts\ServiceManagementFormWithXAML\MainWindow.xaml"

$inputXAML = Get-Content -Path $xamlFile -Raw
$inputXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
[XML]$XAML=$inputXAML

# Loads in the Windows Form from the XAML file
$Reader = New-Object System.Xml.XmlNodeReader $XAML
try {
    $psform=[Windows.Markup.XamlReader]::Load($Reader)
}
catch {
    Write-Host $_.Exception
    throw
}

# Change the Name objects in the XAML file to variables with the name format of var_[name]. This allows us to reference them here.
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try{
        Set-Variable -Name "var_$($_.Name)" -Value $psform.FindName($_.Name)
    }catch{
        throw
    }
}

# Retrieves the variables created above
Get-Variable var_*

# Get list of services and add into drop-down box
Get-Service | ForEach-Object {$var_ServiceDropDown.Items.Add($_.name)}

function GetServiceStatus {
    $NameOfService = $var_ServiceDropDown.SelectedItem
    $ServiceDetails = Get-Service -Name $NameOfService | Select-Object *
    $var_Status.Content = $ServiceDetails.status

    if ($var_Status.Content -eq 'Running') {
        $var_Status.Foreground = '#32CD32'
    } elseif ($var_Status.Content -eq 'Stopped') {
        $var_Status.Foreground = '#EE4B2B'
    }
}

# This executes the function GetServiceStatus based on what service user selects in the ServiceNameBox combo box (drop-down box)
$var_ServiceDropDown.Add_SelectionChanged({GetServiceStatus})

function RestartService {
    if ($var_ServiceDropDown.SelectedItem -eq "Stopped") {
        $var_CurrentActionLabel.Content = 'Service cannot be restarted.'
    } else {
        $var_CurrentActionLabel.Content = "Restarting service."
        Restart-Service -Name $var_ServiceDropDown.SelectedItem
        GetServiceStatus
        $var_ServiceDropDown.Add_SelectionChanged({GetServiceStatus})
        $var_CurrentActionLabel.Content = "The service has been restarted."
    }
}

function StartService {
    if ($var_ServiceDropDown.SelectedItem -eq "Running") {
        $var_CurrentActionLabel.Content = "This service is already running."
    } else {
        $var_CurrentActionLabel.Content = "Starting service."
        Start-Service -Name $var_ServiceDropDown.SelectedItem
        GetServiceStatus
        $var_ServiceDropDown.Add_SelectionChanged({GetServiceStatus})
        $var_CurrentActionLabel.Content = "The service has been Started."
    }
}

function StopService {
    If ($var_ServiceDropDown.SelectedItem -eq "Stopped") {
        $var_CurrentActionLabel.Content = "This service is already stopped."
    } else {
        $var_CurrentActionLabel.Content = "Stopping service."
        Stop-Service -Name $var_ServiceDropDown.SelectedItem
        GetServiceStatus
        $var_ServiceDropDown.Add_SelectionChanged({GetServiceStatus})
        $var_CurrentActionLabel.Content = "The service has stopped."
    }
}

$var_RestartButton.Add_Click({RestartService})
$var_StartButton.Add_Click({StartService})
$var_StopButton.Add_Click({StopService})

$psform.ShowDialog()