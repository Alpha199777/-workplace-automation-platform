

# =======================
# CONFIG
# =======================
$siteUrl  = "https://alone396.sharepoint.com/sites/WorkplaceAutomation"
$listName  = "Registre des Projets"
$clientId  = "82136df3-a5c7-46d9-adb4-a9f69b7595ae"
$tenant   = "alone396.onmicrosoft.com"
$model    = "gpt-4.1-mini"  # tu peux changer si besoin

# =======================
# CHECK API KEY
# =======================
$apiKey = $env:OPENAI_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw "OPENAI_API_KEY introuvable. Fais: setx OPENAI_API_KEY 'xxx' puis relance PowerShell."
}

# =======================
# CONNECT SHAREPOINT
# =======================
Connect-PnPOnline -Url $siteUrl -ClientId $clientId -Tenant $tenant -DeviceLogin

# =======================
# FUNCTION: CALL OPENAI (avec retry 429 + extraction JSON)
# =======================
function Invoke-OpenAIProjectAI {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Impact
    )

    $maxRetries = 5
    $delay      = 10
    $attempt    = 0

    while ($attempt -lt $maxRetries) {
        $attempt++
        try {
            $prompt = @"
Tu es un assistant IA pour une gouvernance SharePoint.

Projet:
Titre: $Title
Description: $Description
Impact: $Impact

Réponds UNIQUEMENT avec un JSON valide, sans backticks, sans ```.
Format exact:
{"summary":"...","tags":["...","...","..."],"recommendations":["...","...","..."]}
"@

            $headers = @{
                "Authorization" = "Bearer $env:OPENAI_API_KEY"
                "Content-Type"  = "application/json"
            }

            # Endpoint standard avec response_format JSON garanti
            $bodyObj = @{
                model           = $model
                response_format = @{ type = "json_object" }
                messages        = @(
                    @{ role = "user"; content = $prompt }
                )
            }

            $resp = Invoke-RestMethod `
                -Method POST `
                -Uri "https://api.openai.com/v1/chat/completions" `
                -Headers $headers `
                -Body ($bodyObj | ConvertTo-Json -Depth 10)

            # DEBUG: affiche la structure complète de la réponse
            Write-Host "===== OPENAI RAW START =====" -ForegroundColor Cyan
            Write-Host ($resp | ConvertTo-Json -Depth 10)
            Write-Host "===== OPENAI RAW END =====" -ForegroundColor Cyan

            # /v1/responses : le texte est dans output[0].content[0].text
            $raw = $null
            try { $raw = $resp.output[0].content[0].text } catch {}

            # Fallback -> /v1/chat/completions style
            if ([string]::IsNullOrWhiteSpace($raw)) {
                try { $raw = $resp.choices[0].message.content } catch {}
            }

            # Fallback -> output_text (ancienne convention)
            if ([string]::IsNullOrWhiteSpace($raw)) {
                try { $raw = $resp.output_text } catch {}
            }

            if ([string]::IsNullOrWhiteSpace($raw)) {
                throw "Réponse OpenAI vide. Voir le JSON brut ci-dessus pour diagnostiquer."
            }

            # Extraction JSON (même si du texte parasite existe)
            $m = [regex]::Match($raw, "\{[\s\S]*\}")
            if (-not $m.Success) {
                throw "Aucun JSON détecté dans la réponse OpenAI."
            }

            return ($m.Value | ConvertFrom-Json)
        }
        catch {
            $msg = $_.Exception.Message

            # Gestion 429 (Too Many Requests)
            if ($msg -match "429|Too Many Requests") {
                Write-Host "⏳ 429 Too Many Requests -> attente ${delay}s puis retry ($attempt/$maxRetries)" -ForegroundColor Yellow
                Start-Sleep -Seconds $delay
                $delay = [Math]::Min([int]($delay * 1.8), 60)
                continue
            }

            # Autres erreurs : on remonte
            throw $_
        }
    }

    throw "Échec OpenAI après $maxRetries tentatives (429)."
}

# =======================
# GET ITEMS TO PROCESS
# =======================
# Important: AI_Status est un champ Choice, donc on le lit via FieldValues.
$items = Get-PnPListItem -List $listName -PageSize 200 -Fields "ID","Title","Description","Impact","AI_Status"

$todo = $items | Where-Object {
    $s = $_.FieldValues["AI_Status"]
    [string]::IsNullOrWhiteSpace([string]$s) -or [string]$s -ne "Done"
}

Write-Host "🧠 Items à traiter: $($todo.Count)" -ForegroundColor Cyan

# =======================
# PROCESS
# =======================
foreach ($item in $todo) {
    $id = $item.Id

    try {
        $title     = [string]$item.FieldValues["Title"]
        $desc      = [string]$item.FieldValues["Description"]
        $impactRaw = $item.FieldValues["Impact"]

        # Impact peut parfois être tableau -> on normalise
        if ($impactRaw -is [System.Array]) { $impact = ($impactRaw -join ", ") }
        else { $impact = [string]$impactRaw }

        Write-Host "➡️ Traitement ID=$id | $title" -ForegroundColor Yellow

        # 1) Appel IA
        $ai = Invoke-OpenAIProjectAI -Title $title -Description $desc -Impact $impact

        # 2) Mise en forme pour SharePoint
        $summary = [string]$ai.summary
        $tags    = @()
        if ($ai.tags) { $tags = @($ai.tags) }
        $recs    = @()
        if ($ai.recommendations) { $recs = @($ai.recommendations) }

        $tagsStr = ($tags -join ", ")
        $recoStr = ($recs -join "`n")

        # 3) Update list item
        Set-PnPListItem -List $listName -Identity $id -Values @{
            "AI_Summary_x0028_"        = $summary
            "AI_Tags"           = $tagsStr
            "AI_Recommendations"= $recoStr
            "AI_Status"         = "Done"
            "AI_LastProcessed"  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "AI_Model"          = $model
        }

        Write-Host "✅ OK ID=$id" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur ID=$id : $($_.Exception.Message)" -ForegroundColor Red

        # Marquer en erreur dans la liste
        try {
            Set-PnPListItem -List $listName -Identity $id -Values @{
                "AI_Status"        = "Error"
                "AI_LastProcessed" = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                "AI_Model"         = $model
            }
        } catch {}
    }
}

Write-Host "🎉 Terminé." -ForegroundColor Green
