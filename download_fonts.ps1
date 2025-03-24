$fonts = @(
    @{
        Name = "Montserrat-Regular.ttf"
        Url = "https://github.com/google/fonts/raw/main/ofl/montserrat/static/Montserrat-Regular.ttf"
    },
    @{
        Name = "Montserrat-Medium.ttf"
        Url = "https://github.com/google/fonts/raw/main/ofl/montserrat/static/Montserrat-Medium.ttf"
    },
    @{
        Name = "Montserrat-Bold.ttf"
        Url = "https://github.com/google/fonts/raw/main/ofl/montserrat/static/Montserrat-Bold.ttf"
    }
)

foreach ($font in $fonts) {
    $outputPath = "assets/fonts/$($font.Name)"
    Write-Host "Downloading $($font.Name)..."
    Invoke-WebRequest -Uri $font.Url -OutFile $outputPath
    Write-Host "Downloaded to $outputPath"
}