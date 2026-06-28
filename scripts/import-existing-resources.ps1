param(
  [string]$VarFile = "terraform.tfvars"
)

$ErrorActionPreference = "Stop"

function Test-Command {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function ConvertFrom-TerraformJson {
  param([string]$Value)
  $parsed = $Value | ConvertFrom-Json
  if ($parsed -is [string]) {
    return $parsed | ConvertFrom-Json
  }
  return $parsed
}

function Invoke-TerraformConsoleJson {
  param([string]$Expression)

  $terraformArgsStr = 'console -no-color'
  if (Test-Path -LiteralPath $VarFile) {
    $terraformArgsStr += ' -var-file="' + $VarFile + '"'
  }

  $psi = [System.Diagnostics.ProcessStartInfo]::new('terraform', $terraformArgsStr)
  $psi.RedirectStandardInput  = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute        = $false
  $psi.WorkingDirectory       = (Get-Location).Path

  $proc = [System.Diagnostics.Process]::new()
  $proc.StartInfo = $psi
  $proc.Start() | Out-Null

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Expression + "`n")
  $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
  $proc.StandardInput.BaseStream.Flush()
  $proc.StandardInput.BaseStream.Close()

  $stdoutText = $proc.StandardOutput.ReadToEnd()
  $stderrText = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()

  if ($proc.ExitCode -ne 0) {
    throw "terraform console failed (exit $($proc.ExitCode)): $stderrText"
  }

  return ConvertFrom-TerraformJson $stdoutText.Trim()
}

function Test-TerraformState {
  param([string]$Address)
  terraform state show $Address 1>$null 2>$null
  return $LASTEXITCODE -eq 0
}

function Import-IfExists {
  param(
    [string]$Address,
    [string]$ImportId,
    [scriptblock]$Exists
  )

  if (Test-TerraformState $Address) {
    Write-Host "Already in Terraform state: $Address"
    return
  }

  $existsResult = & $Exists
  if (-not $existsResult) {
    Write-Host "Does not exist yet, Terraform will create it: $Address"
    return
  }

  Write-Host "Importing existing resource: $ImportId -> $Address"
  terraform import $Address $ImportId
  if ($LASTEXITCODE -ne 0) {
    throw "terraform import failed for $Address."
  }
}

if (-not (Test-Command "terraform")) {
  throw "terraform CLI was not found in PATH."
}

if (-not (Test-Command "gcloud")) {
  throw "gcloud CLI was not found in PATH."
}

$nl = "`n"
$tfExpression = "jsonencode({$nl" +
  "  project_id = var.project_id$nl" +
  "  vm_name = var.vm_name$nl" +
  "  vm_zone = var.vm_zone$nl" +
  "  db_instance_name = var.db_instance_name$nl" +
  "  db_databases = {$nl" +
  "    for key, database in var.db_databases :$nl" +
  "    key => {$nl" +
  "      database_name = database.database_name$nl" +
  "      user_name = database.user_name$nl" +
  "    }$nl" +
  "  }$nl" +
  "  db_secret_ids = local.db_secret_ids$nl" +
  "  additional_secret_ids = {$nl" +
  "    for key, secret in var.secret_manager_secrets :$nl" +
  "    key => secret.secret_id$nl" +
  "  }$nl" +
  "  buckets = local.buckets$nl" +
  "})"

$config = Invoke-TerraformConsoleJson $tfExpression

$projectId = $config.project_id
$instanceName = $config.db_instance_name

foreach ($bucket in $config.buckets.PSObject.Properties) {
  $key = $bucket.Name
  $bucketName = $bucket.Value.name

  Import-IfExists `
    -Address "module.buckets[`"$key`"].google_storage_bucket.this" `
    -ImportId $bucketName `
    -Exists {
      gcloud storage buckets describe "gs://$bucketName" --format "value(name)" 1>$null 2>$null
      return $LASTEXITCODE -eq 0
    }
}

Import-IfExists `
  -Address "module.vm.google_compute_instance.this" `
  -ImportId "projects/$projectId/zones/$($config.vm_zone)/instances/$($config.vm_name)" `
  -Exists {
    gcloud compute instances describe $config.vm_name --zone $config.vm_zone --project $projectId --format "value(name)" 1>$null 2>$null
    return $LASTEXITCODE -eq 0
  }

Import-IfExists `
  -Address "module.postgres.google_sql_database_instance.this" `
  -ImportId "projects/$projectId/instances/$instanceName" `
  -Exists {
    gcloud sql instances describe $instanceName --project $projectId --format "value(name)" 1>$null 2>$null
    return $LASTEXITCODE -eq 0
  }

foreach ($database in $config.db_databases.PSObject.Properties) {
  $key = $database.Name
  $databaseName = $database.Value.database_name
  $userName = $database.Value.user_name
  $secretId = $config.db_secret_ids.$key

  Import-IfExists `
    -Address "module.postgres.google_sql_database.this[`"$key`"]" `
    -ImportId "projects/$projectId/instances/$instanceName/databases/$databaseName" `
    -Exists {
      gcloud sql databases describe $databaseName --instance $instanceName --project $projectId --format "value(name)" 1>$null 2>$null
      return $LASTEXITCODE -eq 0
    }

  Import-IfExists `
    -Address "module.postgres.google_sql_user.this[`"$key`"]" `
    -ImportId "$projectId/$instanceName/$userName" `
    -Exists {
      $users = gcloud sql users list --instance $instanceName --project $projectId --filter "name=$userName" --format "value(name)" 2>$null
      return $LASTEXITCODE -eq 0 -and $users -contains $userName
    }

  Import-IfExists `
    -Address "google_secret_manager_secret.db_password[`"$key`"]" `
    -ImportId "projects/$projectId/secrets/$secretId" `
    -Exists {
      gcloud secrets describe $secretId --project $projectId --format "value(name)" 1>$null 2>$null
      return $LASTEXITCODE -eq 0
    }
}

foreach ($secret in $config.additional_secret_ids.PSObject.Properties) {
  $key = $secret.Name
  $secretId = $secret.Value

  Import-IfExists `
    -Address "google_secret_manager_secret.additional[`"$key`"]" `
    -ImportId "projects/$projectId/secrets/$secretId" `
    -Exists {
      gcloud secrets describe $secretId --project $projectId --format "value(name)" 1>$null 2>$null
      return $LASTEXITCODE -eq 0
    }
}