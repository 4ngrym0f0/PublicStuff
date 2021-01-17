$CommonParams = @{
    ErrorAction = 'Stop'
    Verbose     = $false
} # Common params

## OBTAIN CONSUMER KEY AND CONSUMER SECRET FROM DEVELOPER SETTINGS
##
## Application registration can be found here: https://www.discogs.com/settings/developers
##
## You only need to register once per application you make. You should not share your consumer secret, as it acts as a sort of password for your requests.

$AppName   = '<YOUR_APP_NAME_HERE>'
$AppKey    = '<YOUR_CONSUMER_KEY_HERE>'
$AppSecret = '<YOUR_CONSUMER_SECRET_HERE>'


### SEND A GET REQUEST TO THE DISCOGS REQUEST TOKEN URL

$AuthChunks = [Ordered]@{
    'OAuth oauth_consumer_key' = $AppKey
    oauth_nonce                = Get-Random
    oauth_signature            = $AppSecret + '&'
    oauth_signature_method     = 'PLAINTEXT'
    oauth_timestamp            = $([DateTimeOffset]::Now.ToUnixTimeSeconds())
}

$AuthString = $null

foreach ($Chunk in $AuthChunks.GetEnumerator())
{
    $AuthString += $Chunk.Key + '="' + $Chunk.Value + '", '
}

$AuthString = $AuthString.TrimEnd(', ')

$Header = @{
    Authorization = $AuthString
    'User-Agent'  = $AppName
}

$GetParams = $CommonParams + @{
    Headers = $Header
    Method  = 'GET'
    Uri     = 'https://api.discogs.com/oauth/request_token'
}

$AATString = Invoke-RestMethod @GetParams


### REDIRECT YOUR USER TO THE DISCOGS AUTHORIZE PAGE

Start-Process "https://discogs.com/oauth/authorize?$AATString" @CommonParams


### SEND A POST REQUEST TO THE DISCOGS ACCESS TOKEN URL

$VerifierCode = Read-Host 'Provide the generated Verifier Code'
$AAT          = ($AATString.Split('&')[0]).Split('=')[1]
$AATSecret    = ($AATString.Split('&')[1]).Split('=')[1]

$AuthChunks = [Ordered]@{
    'OAuth oauth_consumer_key' = $AppKey
    oauth_nonce                = Get-Random
    oauth_token                = $AAT
    oauth_signature            = $AppSecret + '&' + $AATSecret
    oauth_signature_method     = 'PLAINTEXT'
    oauth_timestamp            = $([DateTimeOffset]::Now.ToUnixTimeSeconds())
    oauth_verifier             = $VerifierCode
}

$AuthString = $null

foreach ($Chunk in $AuthChunks.GetEnumerator())
{
    $AuthString += $Chunk.Key + '="' + $Chunk.Value + '", '
}

$AuthString = $AuthString.TrimEnd(', ')

$Header = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
    Authorization  = $AuthString
    'User-Agent'   = $AppName
}

$PostParams = $CommonParams + @{
    Headers = $Header
    Method  = 'POST'
    Uri     = 'https://api.discogs.com/oauth/access_token'
}

$FinalAATString = Invoke-RestMethod @RequestParams


### SEND AUTHENTICATED REQUESTS TO DISCOGS ENDPOINTS

$FinalAAT       = ($FinalAATString.Split('&')[0]).Split('=')[1]
$FinalAATSecret = ($FinalAATString.Split('&')[1]).Split('=')[1]

## The below constructed Header MUST be included in any future API calls 
## to benefit from the just generated OAuth App token
$AuthChunks = [Ordered]@{
    'OAuth oauth_consumer_key' = $AppKey
    oauth_nonce                = Get-Random
    oauth_token                = $FinalAAT
    oauth_signature            = $AppSecret + '&' + $FinalAATSecret
    oauth_signature_method     = 'PLAINTEXT'
    oauth_timestamp            = $([DateTimeOffset]::Now.ToUnixTimeSeconds())
}

$AuthString = $null

foreach ($Chunk in $AuthChunks.GetEnumerator())
{
    $AuthString += $Chunk.Key + '="' + $Chunk.Value + '", '
}

$AuthString = $AuthString.TrimEnd(', ')

$Header = @{
    Authorization  = $AuthString
}

$OAuthTestParams = $CommonParams + @{
    Header = $Header
    Method = 'GET'
    Uri    = 'https://api.discogs.com/oauth/identity'
}

Invoke-RestMethod @OAuthTestParams

Write-Host -NoNewline 'OAuth Token string: ' -ForegroundColor Cyan; Write-Host $FinalAATString -ForegroundColor Green
Write-Host -NoNewline 'OAuth Token: '-ForegroundColor Cyan; Write-Host $FinalAAT -ForegroundColor Green
Write-Host -NoNewline 'OAuth Token secret: '-ForegroundColor Cyan; Write-Host $FinalAATSecret -ForegroundColor Green