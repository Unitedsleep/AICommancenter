function ConvertFrom-Color { 
    [alias('Convert-FromColor')]
    [CmdletBinding()]
    param ([ValidateScript({ if ($($_ -in $Script:RGBColors.Keys -or $_ -match "^#([A-Fa-f0-9]{6})$" -or $_ -eq "") -eq $false) { throw "The Input value is not a valid colorname nor an valid color hex code." } else { $true } })]
        [alias('Colors')][string[]] $Color,
        [switch] $AsDecimal,
        [switch] $AsDrawingColor)
    $Colors = foreach ($C in $Color) {
        $Value = $Script:RGBColors."$C"
        if ($C -match "^#([A-Fa-f0-9]{6})$") {
            $C
            continue
        }
        if ($null -eq $Value) { continue }
        $HexValue = Convert-Color -RGB $Value
        Write-Verbose "Convert-FromColor - Color Name: $C Value: $Value HexValue: $HexValue"
        if ($AsDecimal) { [Convert]::ToInt64($HexValue, 16) } elseif ($AsDrawingColor) { [System.Drawing.Color]::FromArgb("#$($HexValue)") } else { "#$($HexValue)" }
    }
    $Colors
}
function Remove-EmptyValue { 
    [alias('Remove-EmptyValues')]
    [CmdletBinding()]
    param([alias('Splat', 'IDictionary')][Parameter(Mandatory)][System.Collections.IDictionary] $Hashtable,
        [string[]] $ExcludeParameter,
        [switch] $Recursive,
        [int] $Rerun,
        [switch] $DoNotRemoveNull,
        [switch] $DoNotRemoveEmpty,
        [switch] $DoNotRemoveEmptyArray,
        [switch] $DoNotRemoveEmptyDictionary)
    foreach ($Key in [string[]] $Hashtable.Keys) { if ($Key -notin $ExcludeParameter) { if ($Recursive) { if ($Hashtable[$Key] -is [System.Collections.IDictionary]) { if ($Hashtable[$Key].Count -eq 0) { if (-not $DoNotRemoveEmptyDictionary) { $Hashtable.Remove($Key) } } else { Remove-EmptyValue -Hashtable $Hashtable[$Key] -Recursive:$Recursive } } else { if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) { $Hashtable.Remove($Key) } } } else { if (-not $DoNotRemoveNull -and $null -eq $Hashtable[$Key]) { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmpty -and $Hashtable[$Key] -is [string] -and $Hashtable[$Key] -eq '') { $Hashtable.Remove($Key) } elseif (-not $DoNotRemoveEmptyArray -and $Hashtable[$Key] -is [System.Collections.IList] -and $Hashtable[$Key].Count -eq 0) { $Hashtable.Remove($Key) } } } }
    if ($Rerun) { for ($i = 0; $i -lt $Rerun; $i++) { Remove-EmptyValue -Hashtable $Hashtable -Recursive:$Recursive } }
}
function Convert-Color { 
    <#
    .Synopsis
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
    .Description
    This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
    .Parameter RBG
    Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
    .Parameter HEX
    Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
    .Example
    .\convert-color -hex FFFFFF
    Converts hex value FFFFFF to RGB

    .Example
    .\convert-color -RGB 123,200,255
    Converts Red = 123 Green = 200 Blue = 255 to Hex value

    #>
    param([Parameter(ParameterSetName = "RGB", Position = 0)]
        [ValidateScript({ $_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$' })]
        $RGB,
        [Parameter(ParameterSetName = "HEX", Position = 0)]
        [ValidateScript({ $_ -match '[A-Fa-f0-9]{6}' })]
        [string]
        $HEX)
    switch ($PsCmdlet.ParameterSetName) {
        "RGB" {
            if ($null -eq $RGB[2]) { Write-Error "Value missing. Please enter all three values seperated by comma." }
            $red = [convert]::Tostring($RGB[0], 16)
            $green = [convert]::Tostring($RGB[1], 16)
            $blue = [convert]::Tostring($RGB[2], 16)
            if ($red.Length -eq 1) { $red = '0' + $red }
            if ($green.Length -eq 1) { $green = '0' + $green }
            if ($blue.Length -eq 1) { $blue = '0' + $blue }
            Write-Output $red$green$blue
        }
        "HEX" {
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}
function Add-PDFDocumentContent {
    [CmdletBinding()]
    param(
        [object] $Object
    )
    if ($Script:Document) {
        $null = $Script:Document.Add($Object)
    } else {
        $Splat = $Script:PDFStart.DocumentSettings
        $Settings = New-PDFPage @Splat #-MarginTop $MarginTop -MarginBottom $MarginBottom -MarginLeft $MarginLeft -MarginRight $MarginRight -PageSize $PageSize -Rotate:$Rotate.IsPresent
        New-InternalPDFPage -PageSize $Settings.Settings.PageSize -Rotate:$Settings.Settings.Rotate -MarginTop $MarginTop -MarginBottom $MarginBottom -MarginLeft $MarginLeft -MarginRight $MarginRight
        $null = $Script:Document.Add($Object)
    }
}
class CustomSplitter : iText.Kernel.Utils.PdfSplitter {
    [int] $_order
    [string] $_destinationFolder
    [string] $_outputName

    CustomSplitter([iText.Kernel.Pdf.PdfDocument] $pdfDocument, [string] $destinationFolder, [string] $OutputName) : base($pdfDocument) {
        $this._destinationFolder = $destinationFolder
        $this._order = 0
        $this._outputName = $OutputName
    }

    [iText.Kernel.Pdf.PdfWriter] GetNextPdfWriter([iText.Kernel.Utils.PageRange] $documentPageRange) {
        $Name = -join ($this._outputName, $this._order++, ".pdf")
        $Path = [IO.Path]::Combine($this._destinationFolder, $Name)
        return [iText.Kernel.Pdf.PdfWriter]::new($Path)
    }
}

# [iText.Kernel.Geom.Vector]::I1
<#
    RenderText([iText.Kernel.Pdf.Canvas.Parser.Data.TextRenderInfo] $renderInfo) {
        [string] $curFont = $renderInfo.GetFont().PostscriptFontName
        #//Check if faux bold is used
        if ((renderInfo.GetTextRenderMode() == (int)TextRenderMode.FillThenStrokeText)) {
            $curFont += "-Bold";
        }

        #//This code assumes that if the baseline changes then we're on a newline
        [iText.Kernel.Geom.Vector] $curBaseline = $renderInfo.GetBaseline().GetStartPoint();
        [iText.Kernel.Geom.Vector] $topRight = $renderInfo.GetAscentLine().GetEndPoint();
        [iText.Kernel.Geom.Rectangle] $rect = [iText.Kernel.Geom.Rectangle]::new($curBaseline[Vector.I1], $curBaseline[Vector.I2], $topRight[Vector.I1], $topRight[Vector.I2]);
        [Single] $curFontSize = $rect.Height;

        #//See if something has changed, either the baseline, the font or the font size
        if (($this.lastBaseLine -eq $null) -or ($curBaseline[Vector.I2] -ne $lastBaseLine[Vector.I2]) -or ($curFontSize -ne $lastFontSize) -or ($curFont -ne $lastFont)) {
            #//if we've put down at least one span tag close it
            if (($this.lastBaseLine -ne $null)) {
                $this.result.AppendLine("</span>");
            }
            #//If the baseline has changed then insert a line break
            if (($this.lastBaseLine -ne $null) -and ($curBaseline[Vector.I2] -ne $lastBaseLine[Vector.I2]) {
                $this.result.AppendLine("<br />");
            }
            #//Create an HTML tag with appropriate styles
            $this.result.AppendFormat("<span style=`"font-family: { 0 }; font-size: { 1 }`">", $curFont, $curFontSize);
        }
        #//Append the current text
        $this.result.Append($renderInfo.GetText());

        #//Set currently used properties
        $this.lastBaseLine = curBaseline;
        $this.lastFontSize = curFontSize;
        $this.lastFont = curFont;
    }
#>
Enum TextRenderMode {
    FillText = 0
    StrokeText = 1
    FillThenStrokeText = 2
    Invisible = 3
    FillTextAndAddToPathForClipping = 4
    StrokeTextAndAddToPathForClipping = 5
    FillThenStrokeTextAndAddToPathForClipping = 6
    AddTextToPaddForClipping = 7
}
class TextWithFontExtractionStategy : iText.Kernel.Pdf.Canvas.Parser.Listener.ITextExtractionStrategy {
    #HTML buffer
    [System.Text.StringBuilder] $result = [System.Text.StringBuilder]::new()

    #Store last used properties
    [iText.Kernel.Geom.Vector] $lastBaseLine
    [string] $lastFont
    [single] $lastFontSize

    RenderText([iText.Kernel.Pdf.Canvas.Parser.Data.TextRenderInfo] $renderInfo) {
        [string] $curFont = $renderInfo.GetFont().PostscriptFontName;
        #//Check if faux bold is used
        if ($renderInfo.GetTextRenderMode() -eq [int][TextRenderMode]::FillThenStrokeText) {
            $curFont += "-Bold";
        }

        #//This code assumes that if the baseline changes then we're on a newline
        [iText.Kernel.Geom.Vector] $curBaseline = $renderInfo.GetBaseline().GetStartPoint();
        [iText.Kernel.Geom.Vector] $topRight = $renderInfo.GetAscentLine().GetEndPoint();
        [iText.Kernel.Geom.Rectangle] $rect = [iText.Kernel.Geom.Rectangle]::new($curBaseline, $curBaseline, $topRight, $topRight);
        [Single] $curFontSize = $rect.Height;

        #//See if something has changed, either the baseline, the font or the font size
        if (($null -eq $this.lastBaseLine) -or ($curBaseline -ne $this.lastBaseLine) -or ($curFontSize -ne $this.lastFontSize) -or ($curFont -ne $this.lastFont)) {
            #//if we've put down at least one span tag close it
            if ($null -ne $this.lastBaseLine) {
                $this.result.AppendLine("</span>");
            }
            #//If the baseline has changed then insert a line break
            if (($null -ne $this.lastBaseLine) -and ($curBaseline -ne $this.lastBaseLine)) {
                $this.result.AppendLine("<br />");
            }
            #//Create an HTML tag with appropriate styles
            $this.result.AppendFormat("<span style=`"font-family: { 0 }; font-size: { 1 }`">", $curFont, $curFontSize);
        }
        #//Append the current text
        $this.result.Append($renderInfo.GetText());

        #//Set currently used properties
        $this.lastBaseLine = $curBaseline;
        $this.lastFontSize = $curFontSize;
        $this.lastFont = $curFont;
    }

    [string] GetResultantText() {
        #//If we wrote anything then we'll always have a missing closing tag so close it here
        if ($this.result.Length -gt 0) {
            $this.result.Append("</span>");
        }
        return $this.result.ToString();
    }
    [System.Collections.Generic.ICollection[iText.Kernel.Pdf.Canvas.Parser.EventType]] GetSupportedEvents() {
        return $null
    }
    [void] EventOccurred([iText.Kernel.Pdf.Canvas.Parser.Data.IEventData] $data, [iText.Kernel.Pdf.Canvas.Parser.EventType] $type) {
        return
    }
}
# Validation for Fonts
$Script:PDFFont = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    ([iText.IO.Font.Constants.StandardFonts] | Get-Member -Static -MemberType Property).Name | Where-Object { $_ -like "*$wordToComplete*" }
}
$Script:PDFFontValidation = {
    $Array = @(
        (& $Script:PDFFont)
        ''
    )
    $_ -in $Array
}
$Script:PDFFontList = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    @(
        ([iText.IO.Font.Constants.StandardFonts] | Get-Member -Static -MemberType Property).Name
        if ($Script:Fonts.Keys) { $Script:Fonts.Keys }
    ) | Where-Object { $_ -like "*$wordToComplete*" }
}
$Script:PDFFontValidationList = {
    $Array = @(
        (& $Script:PDFFont)
        $Script:Fonts.Keys
        ''
    )
    $_ -in $Array
}
function Get-InternalPDFFont {
    [cmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFFontValidationList } )][string] $Font
    )
    if (-not $Script:Fonts[$Font]) {
        # If not defined font, we use contstant fonts
        $ConvertedFont = Get-PDFConstantFont -Font $Font
        $ApplyFont = [iText.Kernel.Font.PdfFontFactory]::CreateFont($ConvertedFont)
    } else {
        # if defined we use whatever we defined
        $ApplyFont = $Script:Fonts[$Font]
    }
    $ApplyFont
}

Register-ArgumentCompleter -CommandName Get-InternalPDFFont -ParameterName Font -ScriptBlock $Script:PDFFontList
function Get-PDFNamedPageSize {
    [CmdletBinding()]
    param(
        [int] $Height,
        [int] $Width
    )

    $PDFSizes = @{
        '33702384' = [PSCustomObject] @{ PageSize = 'A0'; Rotated = $false }
        '23843370' = [PSCustomObject] @{ PageSize = 'A0'; Rotated = $true }
        '23841684' = [PSCustomObject] @{ PageSize = 'A1'; Rotated = $false }
        '16842384' = [PSCustomObject] @{ PageSize = 'A1'; Rotated = $true }
        '10574'    = [PSCustomObject] @{ PageSize = 'A10'; Rotated = $false }
        '74105'    = [PSCustomObject] @{ PageSize = 'A10'; Rotated = $true }
        '16841190' = [PSCustomObject] @{ PageSize = 'A2'; Rotated = $false }
        '11901684' = [PSCustomObject] @{ PageSize = 'A2'; Rotated = $true }
        '1190842'  = [PSCustomObject] @{ PageSize = 'A3'; Rotated = $false }
        '8421190'  = [PSCustomObject] @{ PageSize = 'A3'; Rotated = $true }
        '842595'   = [PSCustomObject] @{ PageSize = 'A4'; Rotated = $false }
        '595842'   = [PSCustomObject] @{ PageSize = 'A4'; Rotated = $true }
        '595420'   = [PSCustomObject] @{ PageSize = 'A5'; Rotated = $false }
        '420595'   = [PSCustomObject] @{ PageSize = 'A5'; Rotated = $true }
        '420298'   = [PSCustomObject] @{ PageSize = 'A6'; Rotated = $false }
        '298420'   = [PSCustomObject] @{ PageSize = 'A6'; Rotated = $true }
        '298210'   = [PSCustomObject] @{ PageSize = 'A7'; Rotated = $false }
        '210298'   = [PSCustomObject] @{ PageSize = 'A7'; Rotated = $true }
        '210148'   = [PSCustomObject] @{ PageSize = 'A8'; Rotated = $false }
        '148210'   = [PSCustomObject] @{ PageSize = 'A8'; Rotated = $true }
        '547105'   = [PSCustomObject] @{ PageSize = 'A9'; Rotated = $false }
        '105547'   = [PSCustomObject] @{ PageSize = 'A9'; Rotated = $true }
        '40082834' = [PSCustomObject] @{ PageSize = 'B0'; Rotated = $false }
        '28344008' = [PSCustomObject] @{ PageSize = 'B0'; Rotated = $true }
        '28342004' = [PSCustomObject] @{ PageSize = 'B1'; Rotated = $false }
        '20042834' = [PSCustomObject] @{ PageSize = 'B1'; Rotated = $true }
        '12488'    = [PSCustomObject] @{ PageSize = 'B10'; Rotated = $false }
        '88124'    = [PSCustomObject] @{ PageSize = 'B10'; Rotated = $true }
        '20041417' = [PSCustomObject] @{ PageSize = 'B2'; Rotated = $false }
        '14172004' = [PSCustomObject] @{ PageSize = 'B2'; Rotated = $true }
        '14171000' = [PSCustomObject] @{ PageSize = 'B3'; Rotated = $false }
        '10001417' = [PSCustomObject] @{ PageSize = 'B3'; Rotated = $true }
        '1000708'  = [PSCustomObject] @{ PageSize = 'B4'; Rotated = $false }
        '7081000'  = [PSCustomObject] @{ PageSize = 'B4'; Rotated = $true }
        '708498'   = [PSCustomObject] @{ PageSize = 'B5'; Rotated = $false }
        '498708'   = [PSCustomObject] @{ PageSize = 'B5'; Rotated = $true }
        '498354'   = [PSCustomObject] @{ PageSize = 'B6'; Rotated = $false }
        '354498'   = [PSCustomObject] @{ PageSize = 'B6'; Rotated = $true }
        '354249'   = [PSCustomObject] @{ PageSize = 'B7'; Rotated = $false }
        '249354'   = [PSCustomObject] @{ PageSize = 'B7'; Rotated = $true }
        '249175'   = [PSCustomObject] @{ PageSize = 'B8'; Rotated = $false }
        '175249'   = [PSCustomObject] @{ PageSize = 'B8'; Rotated = $true }
        '175124'   = [PSCustomObject] @{ PageSize = 'B9'; Rotated = $false }
        '124175'   = [PSCustomObject] @{ PageSize = 'B9'; Rotated = $true }
        '756522'   = [PSCustomObject] @{ PageSize = 'EXECUTIVE'; Rotated = $false }
        '522756'   = [PSCustomObject] @{ PageSize = 'EXECUTIVE'; Rotated = $true }
        '7921224'  = [PSCustomObject] @{ PageSize = 'LEDGER or TABLOID'; Rotated = $false }
        '1224792'  = [PSCustomObject] @{ PageSize = 'LEDGER or TABLOID'; Rotated = $true }
        '1008612'  = [PSCustomObject] @{ PageSize = 'LEGAL'; Rotated = $false }
        '6121008'  = [PSCustomObject] @{ PageSize = 'LEGAL'; Rotated = $true }
        '792612'   = [PSCustomObject] @{ PageSize = 'LETTER'; Rotated = $false }
        '612792'   = [PSCustomObject] @{ PageSize = 'LETTER'; Rotated = $true }
    }
    $Size = $PDFSizes["$Height$Width"]
    if ($Size) {
        return $Size
    } else {
        return [PSCustomObject] @{ PageSize = 'Unknown'; $Rotated = $null }
    }
}
function Initialize-PDF {
    [CmdletBinding()]
    param(
        [Array] $Elements
    )
    foreach ($Element in $Elements) {
        $Splat = $Element.Settings
        if ($Splat) {
            Remove-EmptyValue -Hashtable $Splat
        }
        if ($Element.Type -eq 'Page') {
            if (-not $Script:PDFStart.FirstPageUsed) {
                #$Area = New-PDFArea -PageSize $Element.Settings.PageSize -Rotate:$Element.Settings.Rotate -AreaType ([iText.Layout.Properties.AreaBreakType]::LAST_PAGE)
                #New-InternalPDFPage -PageSize $Element.Settings.PageSize -Rotate:$Element.Settings.Rotate

                # This adds margings to first page if New-PDFOptions is used but no margins were defined on New-PDFPage
                if (-not $Splat.Margins.MarginBottom) {
                    $Splat.Margins.MarginBottom = $Script:PDFStart.DocumentSettings.MarginBottom
                }
                if (-not $Splat.Margins.MarginTop) {
                    $Splat.Margins.MarginTop = $Script:PDFStart.DocumentSettings.MarginTop
                }
                if (-not $Splat.Margins.MarginLeft) {
                    $Splat.Margins.MarginLeft = $Script:PDFStart.DocumentSettings.MarginLeft
                }
                if (-not $Splat.Margins.MarginRight) {
                    $Splat.Margins.MarginRight = $Script:PDFStart.DocumentSettings.MarginRight
                }
                New-InternalPDFPage -PageSize $Splat.PageSize -Rotate:$Splat.Rotate -MarginLeft $Splat.Margins.MarginLeft -MarginTop $Splat.Margins.MarginTop -MarginBottom $Splat.Margins.MarginBottom -MarginRight $Splat.Margins.MarginRight
                #Add-PDFDocumentContent -Object $Area
                $Script:PDFStart.FirstPageUsed = $true
            } else {
                # This fixes margins. Margins have to be added before new PageArea
                $SplatMargins = $Splat.Margins
                New-InternalPDFOptions @SplatMargins

                $Area = New-PDFArea -PageSize $Element.Settings.PageSize -Rotate:$Element.Settings.Rotate
                Add-PDFDocumentContent -Object $Area
            }
            # New-InternalPDFPage -PageSize $Element.Settings.PageSize -Rotate:$Element.Settings.Rotate
            # New-InternalPDFOptions -Settings $Element.Settings
            if ($Element.Settings.PageContent) {
                Initialize-PDF -Elements $Element.Settings.PageContent
            }
        } elseif ($Element.Type -eq 'Text') {
            $Paragraph = New-InternalPDFText @Splat
            foreach ($P in $Paragraph) {
                Add-PDFDocumentContent -Object $P
            }
        } elseif ($Element.Type -eq 'List') {
            New-InternalPDFList -Settings $Element.Settings
        } elseif ($Element.Type -eq 'Paragraph') {

        } elseif ($Element.Type -eq 'Options') {
            $SplatMargins = $Splat.Margins
            New-InternalPDFOptions @SplatMargins
        } elseif ($Element.Type -eq 'Table') {
            $Table = New-InteralPDFTable @Splat
            #$null = $Script:Document.Add($Table)
            Add-PDFDocumentContent -Object $Table
        } elseif ($Element.Type -eq 'Image') {
            New-InternalPDFImage @Splat
        }
    }
}
function New-InternalPDF {
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [string] $Version #,
        #  [ValidateScript( { & $Script:PDFPageSizeValidation } )][string] $PageSize,
        #   [switch] $Rotate
    )

    if ($Version) {
        $PDFVersion = Get-PDFConstantVersion -Version $Version
        $WriterProperties = [iText.Kernel.Pdf.WriterProperties]::new()
        $null = $WriterProperties.SetPdfVersion($PDFVersion)
    }

    try {
        if ($Version) {
            $Script:Writer = [iText.Kernel.Pdf.PdfWriter]::new($FilePath, $WriterProperties)
        } else {
            $Script:Writer = [iText.Kernel.Pdf.PdfWriter]::new($FilePath)
        }
    } catch {
        if ($_.Exception.Message -like '*The process cannot access the file*because it is being used by another process.*') {
            Write-Warning "New-InternalPDF - File $FilePath is in use. Terminating."
            return
        } else {
            Write-Warning "New-InternalPDF - Terminating error: $($_.Exception.Message)"
            return
        }
    }

    if ($Script:Writer) {
        $PDF = [iText.Kernel.Pdf.PdfDocument]::new($Script:Writer)
    } else {
        Write-Warning "New-InternalPDF - Terminating as writer doesn't exists."
        return
    }
    return $PDF
}



<#
function New-InternalPDF {
    param(

    )
    if ($Script:Writer) {
        if ($Script:PDF) {
            #$Script:PDF.Close()
        }
        $Script:PDF = [iText.Kernel.Pdf.PdfDocument]::new($Script:Writer)
    } else {
        Write-Warning "New-InternalPDF - Terminating as writer doesn't exists."
        Exit
    }
}
#>
Register-ArgumentCompleter -CommandName New-InternalPDF -ParameterName PageSize -ScriptBlock $Script:PDFPageSize
Register-ArgumentCompleter -CommandName New-InternalPDF -ParameterName Version -ScriptBlock $Script:PDFVersion
function New-InternalPDFImage {
    [CmdletBinding()]
    param(
        [string] $ImagePath,
        [int] $Width,
        [int] $Height,
        [object] $BackgroundColor,
        [double] $BackgroundColorOpacity
    )

    $ImageData = [iText.IO.Image.ImageDataFactory]::Create($ImagePath)
    $Image = [iText.Layout.Element.Image]::new($ImageData)

    if ($Width) {
        $Image.SetWidth($Width)
    }
    if ($Height) {
        $Image.SetHeight($Height)

    }
    if ($BackgroundColor) {
        <#
        iText.Layout.Element.Image SetBackgroundColor(iText.Kernel.Colors.Color backgroundColor)
        iText.Layout.Element.Image SetBackgroundColor(iText.Kernel.Colors.Color backgroundColor, float opacity)
        iText.Layout.Element.Image SetBackgroundColor(iText.Kernel.Colors.Color backgroundColor, float extraLeft, float extraTop, float extraRight, float extraBottom)
        iText.Layout.Element.Image SetBackgroundColor(iText.Kernel.Colors.Color backgroundColor, float opacity, float extraLeft, float extraTop, float extraRight, float extraBottom)
        #>
        $RGB = [iText.Kernel.Colors.DeviceRgb]::new($BackgroundColor.R, $BackgroundColor.G, $BackgroundColor.B)
        $null = $Image.SetBackgroundColor($RGB)
        if ($BackgroundColorOpacity) {
            $null = $Image.SetOpacity($BackgroundColorOpacity)
        }
    }
    $null = $Script:Document.Add($Image)
}
function New-InternalPDFList {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary] $Settings
    )

    $List = [iText.Layout.Element.List]::new()
    if ($null -ne $Settings.Indent) {
        $null = $List.SetSymbolIndent($Settings.Indent)
    }
    if ($Settings.Symbol) {
        if ($Settings.Symbol -eq 'hyphen') {
            # Default
        } elseif ($Settings.Symbol -eq 'bullet') {
            $Symbol = [regex]::Unescape("\u2022")
            $null = $List.SetListSymbol($Symbol)
        }

    }
    foreach ($ItemSettings in $Settings.Items) {
        $Paragraph = New-InternalPDFText @ItemSettings
        $ListItem = [iText.Layout.Element.ListItem]::new()
        $null = $ListItem.Add($Paragraph)
        $null = $List.Add($ListItem)
    }
    $null = $Script:Document.Add($List)
}
function New-InternalPDFOptions {
    [CmdletBinding()]
    param(
        [nullable[float]] $MarginLeft,
        [nullable[float]] $MarginRight,
        [nullable[float]] $MarginTop,
        [nullable[float]] $MarginBottom
    )

    if ($Script:Document) {
        if ($MarginLeft) {
            $Script:Document.SetLeftMargin($MarginLeft)
        }
        if ($MarginRight) {
            $Script:Document.SetRightMargin($MarginRight)
        }
        if ($MarginTop) {
            $Script:Document.SetTopMargin($MarginTop)
        }
        if ($MarginBottom) {
            $Script:Document.SetBottomMargin($MarginBottom)
        }
    } else {
        # If Document doesn't exists it means we're using New-PDFOptions before New-PDFPage
        # We update DocumentSettings and use it just in case New-PDFPage doesn't have those values used.
        # Workaround, ugly but don't see a better way
        $Script:PDFStart['DocumentSettings']['MarginTop'] = $MarginTop
        $Script:PDFStart['DocumentSettings']['MarginBottom'] = $MarginBottom
        $Script:PDFStart['DocumentSettings']['MarginLeft'] = $MarginLeft
        $Script:PDFStart['DocumentSettings']['MarginRight'] = $MarginRight
    }

    #if ($Settings.PageSize) {
    #   $Script:Document.GetPdfDocument().SetDefaultPageSize([iText.Kernel.Geom.PageSize]::($Settings.PageSize))
    # }
}
function New-InternalPDFPage {
    [CmdletBinding()]
    param(
        [string] $PageSize,
        [switch] $Rotate,
        [nullable[float]] $MarginLeft,
        [nullable[float]] $MarginRight,
        [nullable[float]] $MarginTop,
        [nullable[float]] $MarginBottom
    )

    if ($PageSize -or $Rotate) {
        if ($PageSize) {
            $Page = [iText.Kernel.Geom.PageSize]::($PageSize)
        } else {
            $Page = [iText.Kernel.Geom.PageSize]::Default
        }
        if ($Rotate) {
            $Page = $Page.Rotate()
        }
    }
    if ($Page) {
        $null = $Script:PDF.AddNewPage($Page)
    } else {
        $null = $Script:PDF.AddNewPage()
    }
    $Script:Document = [iText.Layout.Document]::new($Script:PDF)

    if ($Script:Document) {
        if ($MarginLeft) {
            $Script:Document.SetLeftMargin($MarginLeft)
        }
        if ($MarginRight) {
            $Script:Document.SetRightMargin($MarginRight)
        }
        if ($MarginTop) {
            $Script:Document.SetTopMargin($MarginTop)
        }
        if ($MarginBottom) {
            $Script:Document.SetBottomMargin($MarginBottom)
        }
    }
}

Register-ArgumentCompleter -CommandName New-InternalPDFPage -ParameterName PageSize -ScriptBlock $Script:PDFPageSize
function New-InteralPDFTable {
    [CmdletBinding()]
    param(
        [Array] $DataTable
    )

    if ($DataTable[0] -is [System.Collections.IDictionary]) {
        [Array] $ColumnNames = 'Name', 'Value' # $DataTable[0].Keys
        [Array] $TemporaryTable = foreach ($_ in $DataTable) {
            $_.GetEnumerator() | Select-Object Name, Value
        }
    } else {
        [Array] $ColumnNames = $DataTable[0].PSObject.Properties.Name
        [Array] $TemporaryTable = $DataTable
    }

    [iText.layout.element.Table] $Table = [iText.Layout.Element.Table]::new($ColumnNames.Count)
    $Table = $Table.UseAllAvailableWidth()

    foreach ($Column in $ColumnNames) {
        $Splat = @{
            Text = $Column
            #Font      = $Font
            #FontFamily = $FontFamily
            #FontColor = $FontColor
            #FontBold  = $FontBold
        }
        $Paragraph = New-InternalPDFText @Splat
        #$Paragraph = New-PDFText -Text $Column
        [iText.Layout.Element.Cell] $Cell = [iText.Layout.Element.Cell]::new().Add($Paragraph)
        $null = $Table.AddCell($Cell)
    }
    foreach ($_ in $TemporaryTable) {
        foreach ($Column in $ColumnNames) {
            $Splat = @{
                Text = $_.$Column
                #Font      = $Font
                #FontFamily = $FontFamily
                #FontColor = $FontColor
                #FontBold  = $FontBold
            }
            $Paragraph = New-InternalPDFText @Splat
            #$Paragraph = New-PDFText -Text $_.$Column
            [iText.Layout.Element.Cell] $Cell = [iText.Layout.Element.Cell]::new().Add($Paragraph)
            $null = $Table.AddCell($Cell)
        }
    }
    $Table
}
function New-InternalPDFText {
    [CmdletBinding()]
    param(
        [string[]] $Text,
        [ValidateScript( { & $Script:PDFFontValidationList } )][string[]] $Font,
        #[string[]] $FontFamily,
        [ValidateScript( { & $Script:PDFColorValidation } )][string[]] $FontColor,
        [nullable[bool][]] $FontBold
    )

    $Paragraph = [iText.Layout.Element.Paragraph]::new()

    if ($FontBold) {
        [Array] $FontBold = $FontBold
        $DefaultBold = $FontBold[0]
    }
    if ($FontColor) {
        [Array] $FontColor = $FontColor
        $DefaultColor = $FontColor[0]
    }
    if ($Font) {
        [Array] $Font = $Font
        $DefaultFont = $Font[0]
    }

    for ($i = 0; $i -lt $Text.Count; $i++) {
        [iText.Layout.Element.Text] $PDFText = $Text[$i]

        if ($FontBold) {
            if ($null -ne $FontBold[$i]) {
                if ($FontBold[$i]) {
                    $PDFText = $PDFText.SetBold()
                }
            } else {
                if ($DefaultBold) {
                    $PDFText = $PDFText.SetBold()
                }
            }
        }
        if ($FontColor) {
            if ($null -ne $FontColor[$i]) {
                if ($FontColor[$i]) {
                    $ConvertedColor = Get-PDFConstantColor -Color $FontColor[$i]
                    $PDFText = $PDFText.SetFontColor($ConvertedColor)
                }
            } else {
                if ($DefaultColor) {
                    $ConvertedColor = Get-PDFConstantColor -Color $DefaultColor
                    $PDFText = $PDFText.SetFontColor($ConvertedColor)
                }
            }
        }
        if ($Font) {
            if ($null -ne $Font[$i]) {
                if ($Font[$i]) {
                    #$ConvertedFont = Get-PDFConstantFont -Font $Font[$i]
                    #$ApplyFont = [iText.Kernel.Font.PdfFontFactory]::CreateFont($ConvertedFont, [iText.IO.Font.PdfEncodings]::IDENTITY_H, $false)
                    #$ApplyFont = [iText.Kernel.Font.PdfFontFactory]::CreateFont('TIMES_ROMAN', [iText.IO.Font.PdfEncodings]::IDENTITY_H, $false)
                    #$PDFText = $PDFText.SetFont($ApplyFont)
                    $ApplyFont = Get-InternalPDFFont -Font $Font[$i]
                    $PDFText = $PDFText.SetFont($ApplyFont)
                }
            } else {
                if ($DefaultColor) {
                    # $ConvertedFont = Get-PDFConstantFont -Font $DefaultFont
                    # $ApplyFont = [iText.Kernel.Font.PdfFontFactory]::CreateFont($ConvertedFont, [iText.IO.Font.PdfEncodings]::IDENTITY_H, $false)
                    # $PDFText = $PDFText.SetFont($ApplyFont)
                    $ApplyFont = Get-InternalPDFFont -Font $DefaultFont
                    $PDFText = $PDFText.SetFont($ApplyFont)
                }
            }
        } else {
            if ($Script:DefaultFont) {
                $PDFText = $PDFText.SetFont($Script:DefaultFont)
            }
        }
        $null = $Paragraph.Add($PDFText)
    }
    $Paragraph
}
$Script:RGBColors = [ordered] @{
    None                   = $null
    AirForceBlue           = 93, 138, 168
    Akaroa                 = 195, 176, 145
    AlbescentWhite         = 227, 218, 201
    AliceBlue              = 240, 248, 255
    Alizarin               = 227, 38, 54
    Allports               = 18, 97, 128
    Almond                 = 239, 222, 205
    AlmondFrost            = 159, 129, 112
    Amaranth               = 229, 43, 80
    Amazon                 = 59, 122, 87
    Amber                  = 255, 191, 0
    Amethyst               = 153, 102, 204
    AmethystSmoke          = 156, 138, 164
    AntiqueWhite           = 250, 235, 215
    Apple                  = 102, 180, 71
    AppleBlossom           = 176, 92, 82
    Apricot                = 251, 206, 177
    Aqua                   = 0, 255, 255
    Aquamarine             = 127, 255, 212
    Armygreen              = 75, 83, 32
    Arsenic                = 59, 68, 75
    Astral                 = 54, 117, 136
    Atlantis               = 164, 198, 57
    Atomic                 = 65, 74, 76
    AtomicTangerine        = 255, 153, 102
    Axolotl                = 99, 119, 91
    Azure                  = 240, 255, 255
    Bahia                  = 176, 191, 26
    BakersChocolate        = 93, 58, 26
    BaliHai                = 124, 152, 171
    BananaMania            = 250, 231, 181
    BattleshipGrey         = 85, 93, 80
    BayOfMany              = 35, 48, 103
    Beige                  = 245, 245, 220
    Bermuda                = 136, 216, 192
    Bilbao                 = 42, 128, 0
    BilobaFlower           = 181, 126, 220
    Bismark                = 83, 104, 114
    Bisque                 = 255, 228, 196
    Bistre                 = 61, 43, 31
    Bittersweet            = 254, 111, 94
    Black                  = 0, 0, 0
    BlackPearl             = 31, 38, 42
    BlackRose              = 85, 31, 47
    BlackRussian           = 23, 24, 43
    BlanchedAlmond         = 255, 235, 205
    BlizzardBlue           = 172, 229, 238
    Blue                   = 0, 0, 255
    BlueDiamond            = 77, 26, 127
    BlueMarguerite         = 115, 102, 189
    BlueSmoke              = 115, 130, 118
    BlueViolet             = 138, 43, 226
    Blush                  = 169, 92, 104
    BokaraGrey             = 22, 17, 13
    Bole                   = 121, 68, 59
    BondiBlue              = 0, 147, 175
    Bordeaux               = 88, 17, 26
    Bossanova              = 86, 60, 92
    Boulder                = 114, 116, 114
    Bouquet                = 183, 132, 167
    Bourbon                = 170, 108, 57
    Brass                  = 181, 166, 66
    BrickRed               = 199, 44, 72
    BrightGreen            = 102, 255, 0
    BrightRed              = 146, 43, 62
    BrightTurquoise        = 8, 232, 222
    BrilliantRose          = 243, 100, 162
    BrinkPink              = 250, 110, 121
    BritishRacingGreen     = 0, 66, 37
    Bronze                 = 205, 127, 50
    Brown                  = 165, 42, 42
    BrownPod               = 57, 24, 2
    BuddhaGold             = 202, 169, 6
    Buff                   = 240, 220, 130
    Burgundy               = 128, 0, 32
    BurlyWood              = 222, 184, 135
    BurntOrange            = 255, 117, 56
    BurntSienna            = 233, 116, 81
    BurntUmber             = 138, 51, 36
    ButteredRum            = 156, 124, 56
    CadetBlue              = 95, 158, 160
    California             = 224, 141, 60
    CamouflageGreen        = 120, 134, 107
    Canary                 = 255, 255, 153
    CanCan                 = 217, 134, 149
    CannonPink             = 145, 78, 117
    CaputMortuum           = 89, 39, 32
    Caramel                = 255, 213, 154
    Cararra                = 237, 230, 214
    Cardinal               = 179, 33, 52
    CardinGreen            = 18, 53, 36
    CareysPink             = 217, 152, 160
    CaribbeanGreen         = 0, 222, 164
    Carmine                = 175, 0, 42
    CarnationPink          = 255, 166, 201
    CarrotOrange           = 242, 142, 28
    Cascade                = 141, 163, 153
    CatskillWhite          = 226, 229, 222
    Cedar                  = 67, 48, 46
    Celadon                = 172, 225, 175
    Celeste                = 207, 207, 196
    Cello                  = 55, 79, 107
    Cement                 = 138, 121, 93
    Cerise                 = 222, 49, 99
    Cerulean               = 0, 123, 167
    CeruleanBlue           = 42, 82, 190
    Chantilly              = 239, 187, 204
    Chardonnay             = 255, 200, 124
    Charlotte              = 167, 216, 222
    Charm                  = 208, 116, 139
    Chartreuse             = 127, 255, 0
    ChartreuseYellow       = 223, 255, 0
    ChelseaCucumber        = 135, 169, 107
    Cherub                 = 246, 214, 222
    Chestnut               = 185, 78, 72
    ChileanFire            = 226, 88, 34
    Chinook                = 150, 200, 162
    Chocolate              = 210, 105, 30
    Christi                = 125, 183, 0
    Christine              = 181, 101, 30
    Cinnabar               = 235, 76, 66
    Citron                 = 159, 169, 31
    Citrus                 = 141, 182, 0
    Claret                 = 95, 25, 51
    ClassicRose            = 251, 204, 231
    ClayCreek              = 145, 129, 81
    Clinker                = 75, 54, 33
    Clover                 = 74, 93, 35
    Cobalt                 = 0, 71, 171
    CocoaBrown             = 44, 22, 8
    Cola                   = 60, 48, 36
    ColumbiaBlue           = 166, 231, 255
    CongoBrown             = 103, 76, 71
    Conifer                = 178, 236, 93
    Copper                 = 218, 138, 103
    CopperRose             = 153, 102, 102
    Coral                  = 255, 127, 80
    CoralRed               = 255, 64, 64
    CoralTree              = 173, 111, 105
    Coriander              = 188, 184, 138
    Corn                   = 251, 236, 93
    CornField              = 250, 240, 190
    Cornflower             = 147, 204, 234
    CornflowerBlue         = 100, 149, 237
    Cornsilk               = 255, 248, 220
    Cosmic                 = 132, 63, 91
    Cosmos                 = 255, 204, 203
    CostaDelSol            = 102, 93, 30
    CottonCandy            = 255, 188, 217
    Crail                  = 164, 90, 82
    Cranberry              = 205, 96, 126
    Cream                  = 255, 255, 204
    CreamCan               = 242, 198, 73
    Crimson                = 220, 20, 60
    Crusta                 = 232, 142, 90
    Cumulus                = 255, 255, 191
    Cupid                  = 246, 173, 198
    CuriousBlue            = 40, 135, 200
    Cyan                   = 0, 255, 255
    Cyprus                 = 6, 78, 64
    DaisyBush              = 85, 53, 146
    Dandelion              = 250, 218, 94
    Danube                 = 96, 130, 182
    DarkBlue               = 0, 0, 139
    DarkBrown              = 101, 67, 33
    DarkCerulean           = 8, 69, 126
    DarkChestnut           = 152, 105, 96
    DarkCoral              = 201, 90, 73
    DarkCyan               = 0, 139, 139
    DarkGoldenrod          = 184, 134, 11
    DarkGray               = 169, 169, 169
    DarkGreen              = 0, 100, 0
    DarkGreenCopper        = 73, 121, 107
    DarkGrey               = 169, 169, 169
    DarkKhaki              = 189, 183, 107
    DarkMagenta            = 139, 0, 139
    DarkOliveGreen         = 85, 107, 47
    DarkOrange             = 255, 140, 0
    DarkOrchid             = 153, 50, 204
    DarkPastelGreen        = 3, 192, 60
    DarkPink               = 222, 93, 131
    DarkPurple             = 150, 61, 127
    DarkRed                = 139, 0, 0
    DarkSalmon             = 233, 150, 122
    DarkSeaGreen           = 143, 188, 143
    DarkSlateBlue          = 72, 61, 139
    DarkSlateGray          = 47, 79, 79
    DarkSlateGrey          = 47, 79, 79
    DarkSpringGreen        = 23, 114, 69
    DarkTangerine          = 255, 170, 29
    DarkTurquoise          = 0, 206, 209
    DarkViolet             = 148, 0, 211
    DarkWood               = 130, 102, 68
    DeepBlush              = 245, 105, 145
    DeepCerise             = 224, 33, 138
    DeepKoamaru            = 51, 51, 102
    DeepLilac              = 153, 85, 187
    DeepMagenta            = 204, 0, 204
    DeepPink               = 255, 20, 147
    DeepSea                = 14, 124, 97
    DeepSkyBlue            = 0, 191, 255
    DeepTeal               = 24, 69, 59
    Denim                  = 36, 107, 206
    DesertSand             = 237, 201, 175
    DimGray                = 105, 105, 105
    DimGrey                = 105, 105, 105
    DodgerBlue             = 30, 144, 255
    Dolly                  = 242, 242, 122
    Downy                  = 95, 201, 191
    DutchWhite             = 239, 223, 187
    EastBay                = 76, 81, 109
    EastSide               = 178, 132, 190
    EchoBlue               = 169, 178, 195
    Ecru                   = 194, 178, 128
    Eggplant               = 162, 0, 109
    EgyptianBlue           = 16, 52, 166
    ElectricBlue           = 125, 249, 255
    ElectricIndigo         = 111, 0, 255
    ElectricLime           = 208, 255, 20
    ElectricPurple         = 191, 0, 255
    Elm                    = 47, 132, 124
    Emerald                = 80, 200, 120
    Eminence               = 108, 48, 130
    Endeavour              = 46, 88, 148
    EnergyYellow           = 245, 224, 80
    Espresso               = 74, 44, 42
    Eucalyptus             = 26, 162, 96
    Falcon                 = 126, 94, 96
    Fallow                 = 204, 153, 102
    FaluRed                = 128, 24, 24
    Feldgrau               = 77, 93, 83
    Feldspar               = 205, 149, 117
    Fern                   = 113, 188, 120
    FernGreen              = 79, 121, 66
    Festival               = 236, 213, 64
    Finn                   = 97, 64, 81
    FireBrick              = 178, 34, 34
    FireBush               = 222, 143, 78
    FireEngineRed          = 211, 33, 45
    Flamingo               = 233, 92, 75
    Flax                   = 238, 220, 130
    FloralWhite            = 255, 250, 240
    ForestGreen            = 34, 139, 34
    Frangipani             = 250, 214, 165
    FreeSpeechAquamarine   = 0, 168, 119
    FreeSpeechRed          = 204, 0, 0
    FrenchLilac            = 230, 168, 215
    FrenchRose             = 232, 83, 149
    FriarGrey              = 135, 134, 129
    Froly                  = 228, 113, 122
    Fuchsia                = 255, 0, 255
    FuchsiaPink            = 255, 119, 255
    Gainsboro              = 220, 220, 220
    Gallery                = 219, 215, 210
    Galliano               = 204, 160, 29
    Gamboge                = 204, 153, 0
    Ghost                  = 196, 195, 208
    GhostWhite             = 248, 248, 255
    Gin                    = 216, 228, 188
    GinFizz                = 247, 231, 206
    Givry                  = 230, 208, 171
    Glacier                = 115, 169, 194
    Gold                   = 255, 215, 0
    GoldDrop               = 213, 108, 43
    GoldenBrown            = 150, 113, 23
    GoldenFizz             = 240, 225, 48
    GoldenGlow             = 248, 222, 126
    GoldenPoppy            = 252, 194, 0
    Goldenrod              = 218, 165, 32
    GoldenSand             = 233, 214, 107
    GoldenYellow           = 253, 238, 0
    GoldTips               = 225, 189, 39
    GordonsGreen           = 37, 53, 41
    Gorse                  = 255, 225, 53
    Gossamer               = 49, 145, 119
    GrannySmithApple       = 168, 228, 160
    Gray                   = 128, 128, 128
    GrayAsparagus          = 70, 89, 69
    Green                  = 0, 128, 0
    GreenLeaf              = 76, 114, 29
    GreenVogue             = 38, 67, 72
    GreenYellow            = 173, 255, 47
    Grey                   = 128, 128, 128
    GreyAsparagus          = 70, 89, 69
    GuardsmanRed           = 157, 41, 51
    GumLeaf                = 178, 190, 181
    Gunmetal               = 42, 52, 57
    Hacienda               = 155, 135, 12
    HalfAndHalf            = 232, 228, 201
    HalfBaked              = 95, 138, 139
    HalfColonialWhite      = 246, 234, 190
    HalfPearlLusta         = 240, 234, 214
    HanPurple              = 63, 0, 255
    Harlequin              = 74, 255, 0
    HarleyDavidsonOrange   = 194, 59, 34
    Heather                = 174, 198, 207
    Heliotrope             = 223, 115, 255
    Hemp                   = 161, 122, 116
    Highball               = 134, 126, 54
    HippiePink             = 171, 75, 82
    Hoki                   = 110, 127, 128
    HollywoodCerise        = 244, 0, 161
    Honeydew               = 240, 255, 240
    Hopbush                = 207, 113, 175
    HorsesNeck             = 108, 84, 30
    HotPink                = 255, 105, 180
    HummingBird            = 201, 255, 229
    HunterGreen            = 53, 94, 59
    Illusion               = 244, 152, 173
    InchWorm               = 202, 224, 13
    IndianRed              = 205, 92, 92
    Indigo                 = 75, 0, 130
    InternationalKleinBlue = 0, 24, 168
    InternationalOrange    = 255, 79, 0
    IrisBlue               = 28, 169, 201
    IrishCoffee            = 102, 66, 40
    IronsideGrey           = 113, 112, 110
    IslamicGreen           = 0, 144, 0
    Ivory                  = 255, 255, 240
    Jacarta                = 61, 50, 93
    JackoBean              = 65, 54, 40
    JacksonsPurple         = 46, 45, 136
    Jade                   = 0, 171, 102
    JapaneseLaurel         = 47, 117, 50
    Jazz                   = 93, 43, 44
    JazzberryJam           = 165, 11, 94
    JellyBean              = 68, 121, 142
    JetStream              = 187, 208, 201
    Jewel                  = 0, 107, 60
    Jon                    = 79, 58, 60
    JordyBlue              = 124, 185, 232
    Jumbo                  = 132, 132, 130
    JungleGreen            = 41, 171, 135
    KaitokeGreen           = 30, 77, 43
    Karry                  = 255, 221, 202
    KellyGreen             = 70, 203, 24
    Keppel                 = 93, 164, 147
    Khaki                  = 240, 230, 140
    Killarney              = 77, 140, 87
    KingfisherDaisy        = 85, 27, 140
    Kobi                   = 230, 143, 172
    LaPalma                = 60, 141, 13
    LaserLemon             = 252, 247, 94
    Laurel                 = 103, 146, 103
    Lavender               = 230, 230, 250
    LavenderBlue           = 204, 204, 255
    LavenderBlush          = 255, 240, 245
    LavenderPink           = 251, 174, 210
    LavenderRose           = 251, 160, 227
    LawnGreen              = 124, 252, 0
    LemonChiffon           = 255, 250, 205
    LightBlue              = 173, 216, 230
    LightCoral             = 240, 128, 128
    LightCyan              = 224, 255, 255
    LightGoldenrodYellow   = 250, 250, 210
    LightGray              = 211, 211, 211
    LightGreen             = 144, 238, 144
    LightGrey              = 211, 211, 211
    LightPink              = 255, 182, 193
    LightSalmon            = 255, 160, 122
    LightSeaGreen          = 32, 178, 170
    LightSkyBlue           = 135, 206, 250
    LightSlateGray         = 119, 136, 153
    LightSlateGrey         = 119, 136, 153
    LightSteelBlue         = 176, 196, 222
    LightYellow            = 255, 255, 224
    Lilac                  = 204, 153, 204
    Lime                   = 0, 255, 0
    LimeGreen              = 50, 205, 50
    Limerick               = 139, 190, 27
    Linen                  = 250, 240, 230
    Lipstick               = 159, 43, 104
    Liver                  = 83, 75, 79
    Lochinvar              = 86, 136, 125
    Lochmara               = 38, 97, 156
    Lola                   = 179, 158, 181
    LondonHue              = 170, 152, 169
    Lotus                  = 124, 72, 72
    LuckyPoint             = 29, 41, 81
    MacaroniAndCheese      = 255, 189, 136
    Madang                 = 193, 249, 162
    Madras                 = 81, 65, 0
    Magenta                = 255, 0, 255
    MagicMint              = 170, 240, 209
    Magnolia               = 248, 244, 255
    Mahogany               = 215, 59, 62
    Maire                  = 27, 24, 17
    Maize                  = 230, 190, 138
    Malachite              = 11, 218, 81
    Malibu                 = 93, 173, 236
    Malta                  = 169, 154, 134
    Manatee                = 140, 146, 172
    Mandalay               = 176, 121, 57
    MandarianOrange        = 146, 39, 36
    Mandy                  = 191, 79, 81
    Manhattan              = 229, 170, 112
    Mantis                 = 125, 194, 66
    Manz                   = 217, 230, 80
    MardiGras              = 48, 25, 52
    Mariner                = 57, 86, 156
    Maroon                 = 128, 0, 0
    Matterhorn             = 85, 85, 85
    Mauve                  = 244, 187, 255
    Mauvelous              = 255, 145, 175
    MauveTaupe             = 143, 89, 115
    MayaBlue               = 119, 181, 254
    McKenzie               = 129, 97, 60
    MediumAquamarine       = 102, 205, 170
    MediumBlue             = 0, 0, 205
    MediumCarmine          = 175, 64, 53
    MediumOrchid           = 186, 85, 211
    MediumPurple           = 147, 112, 219
    MediumRedViolet        = 189, 51, 164
    MediumSeaGreen         = 60, 179, 113
    MediumSlateBlue        = 123, 104, 238
    MediumSpringGreen      = 0, 250, 154
    MediumTurquoise        = 72, 209, 204
    MediumVioletRed        = 199, 21, 133
    MediumWood             = 166, 123, 91
    Melon                  = 253, 188, 180
    Merlot                 = 112, 54, 66
    MetallicGold           = 211, 175, 55
    Meteor                 = 184, 115, 51
    MidnightBlue           = 25, 25, 112
    MidnightExpress        = 0, 20, 64
    Mikado                 = 60, 52, 31
    MilanoRed              = 168, 55, 49
    Ming                   = 54, 116, 125
    MintCream              = 245, 255, 250
    MintGreen              = 152, 255, 152
    Mischka                = 168, 169, 173
    MistyRose              = 255, 228, 225
    Moccasin               = 255, 228, 181
    Mojo                   = 149, 69, 53
    MonaLisa               = 255, 153, 153
    Mongoose               = 179, 139, 109
    Montana                = 53, 56, 57
    MoodyBlue              = 116, 108, 192
    MoonYellow             = 245, 199, 26
    MossGreen              = 173, 223, 173
    MountainMeadow         = 28, 172, 120
    MountainMist           = 161, 157, 148
    MountbattenPink        = 153, 122, 141
    Mulberry               = 211, 65, 157
    Mustard                = 255, 219, 88
    Myrtle                 = 25, 89, 5
    MySin                  = 255, 179, 71
    NavajoWhite            = 255, 222, 173
    Navy                   = 0, 0, 128
    NavyBlue               = 2, 71, 254
    NeonCarrot             = 255, 153, 51
    NeonPink               = 255, 92, 205
    Nepal                  = 145, 163, 176
    Nero                   = 20, 20, 20
    NewMidnightBlue        = 0, 0, 156
    Niagara                = 58, 176, 158
    NightRider             = 59, 47, 47
    Nobel                  = 152, 152, 152
    Norway                 = 169, 186, 157
    Nugget                 = 183, 135, 39
    OceanGreen             = 95, 167, 120
    Ochre                  = 202, 115, 9
    OldCopper              = 111, 78, 55
    OldGold                = 207, 181, 59
    OldLace                = 253, 245, 230
    OldLavender            = 121, 104, 120
    OldRose                = 195, 33, 72
    Olive                  = 128, 128, 0
    OliveDrab              = 107, 142, 35
    OliveGreen             = 181, 179, 92
    Olivetone              = 110, 110, 48
    Olivine                = 154, 185, 115
    Onahau                 = 196, 216, 226
    Opal                   = 168, 195, 188
    Orange                 = 255, 165, 0
    OrangePeel             = 251, 153, 2
    OrangeRed              = 255, 69, 0
    Orchid                 = 218, 112, 214
    OuterSpace             = 45, 56, 58
    OutrageousOrange       = 254, 90, 29
    Oxley                  = 95, 167, 119
    PacificBlue            = 0, 136, 220
    Padua                  = 128, 193, 151
    PalatinatePurple       = 112, 41, 99
    PaleBrown              = 160, 120, 90
    PaleChestnut           = 221, 173, 175
    PaleCornflowerBlue     = 188, 212, 230
    PaleGoldenrod          = 238, 232, 170
    PaleGreen              = 152, 251, 152
    PaleMagenta            = 249, 132, 239
    PalePink               = 250, 218, 221
    PaleSlate              = 201, 192, 187
    PaleTaupe              = 188, 152, 126
    PaleTurquoise          = 175, 238, 238
    PaleVioletRed          = 219, 112, 147
    PalmLeaf               = 53, 66, 48
    Panache                = 233, 255, 219
    PapayaWhip             = 255, 239, 213
    ParisDaisy             = 255, 244, 79
    Parsley                = 48, 96, 48
    PastelGreen            = 119, 221, 119
    PattensBlue            = 219, 233, 244
    Peach                  = 255, 203, 164
    PeachOrange            = 255, 204, 153
    PeachPuff              = 255, 218, 185
    PeachYellow            = 250, 223, 173
    Pear                   = 209, 226, 49
    PearlLusta             = 234, 224, 200
    Pelorous               = 42, 143, 189
    Perano                 = 172, 172, 230
    Periwinkle             = 197, 203, 225
    PersianBlue            = 34, 67, 182
    PersianGreen           = 0, 166, 147
    PersianIndigo          = 51, 0, 102
    PersianPink            = 247, 127, 190
    PersianRed             = 192, 54, 44
    PersianRose            = 233, 54, 167
    Persimmon              = 236, 88, 0
    Peru                   = 205, 133, 63
    Pesto                  = 128, 117, 50
    PictonBlue             = 102, 153, 204
    PigmentGreen           = 0, 173, 67
    PigPink                = 255, 218, 233
    PineGreen              = 1, 121, 111
    PineTree               = 42, 47, 35
    Pink                   = 255, 192, 203
    PinkFlare              = 191, 175, 178
    PinkLace               = 240, 211, 220
    PinkSwan               = 179, 179, 179
    Plum                   = 221, 160, 221
    Pohutukawa             = 102, 12, 33
    PoloBlue               = 119, 158, 203
    Pompadour              = 129, 20, 83
    Portage                = 146, 161, 207
    PotPourri              = 241, 221, 207
    PottersClay            = 132, 86, 60
    PowderBlue             = 176, 224, 230
    Prim                   = 228, 196, 207
    PrussianBlue           = 0, 58, 108
    PsychedelicPurple      = 223, 0, 255
    Puce                   = 204, 136, 153
    Pueblo                 = 108, 46, 31
    PuertoRico             = 67, 179, 174
    Pumpkin                = 255, 99, 28
    Purple                 = 128, 0, 128
    PurpleMountainsMajesty = 150, 123, 182
    PurpleTaupe            = 93, 57, 84
    QuarterSpanishWhite    = 230, 224, 212
    Quartz                 = 220, 208, 255
    Quincy                 = 106, 84, 69
    RacingGreen            = 26, 36, 33
    RadicalRed             = 255, 32, 82
    Rajah                  = 251, 171, 96
    RawUmber               = 123, 63, 0
    RazzleDazzleRose       = 254, 78, 218
    Razzmatazz             = 215, 10, 83
    Red                    = 255, 0, 0
    RedBerry               = 132, 22, 23
    RedDamask              = 203, 109, 81
    RedOxide               = 99, 15, 15
    RedRobin               = 128, 64, 64
    RichBlue               = 84, 90, 167
    Riptide                = 141, 217, 204
    RobinsEggBlue          = 0, 204, 204
    RobRoy                 = 225, 169, 95
    RockSpray              = 171, 56, 31
    RomanCoffee            = 131, 105, 83
    RoseBud                = 246, 164, 148
    RoseBudCherry          = 135, 50, 96
    RoseTaupe              = 144, 93, 93
    RosyBrown              = 188, 143, 143
    Rouge                  = 176, 48, 96
    RoyalBlue              = 65, 105, 225
    RoyalHeath             = 168, 81, 110
    RoyalPurple            = 102, 51, 152
    Ruby                   = 215, 24, 104
    Russet                 = 128, 70, 27
    Rust                   = 192, 64, 0
    RusticRed              = 72, 6, 7
    Saddle                 = 99, 81, 71
    SaddleBrown            = 139, 69, 19
    SafetyOrange           = 255, 102, 0
    Saffron                = 244, 196, 48
    Sage                   = 143, 151, 121
    Sail                   = 161, 202, 241
    Salem                  = 0, 133, 67
    Salmon                 = 250, 128, 114
    SandyBeach             = 253, 213, 177
    SandyBrown             = 244, 164, 96
    Sangria                = 134, 1, 17
    SanguineBrown          = 115, 54, 53
    SanMarino              = 80, 114, 167
    SanteFe                = 175, 110, 77
    Sapphire               = 6, 42, 120
    Saratoga               = 84, 90, 44
    Scampi                 = 102, 102, 153
    Scarlet                = 255, 36, 0
    ScarletGum             = 67, 28, 83
    SchoolBusYellow        = 255, 216, 0
    Schooner               = 139, 134, 128
    ScreaminGreen          = 102, 255, 102
    Scrub                  = 59, 60, 54
    SeaBuckthorn           = 249, 146, 69
    SeaGreen               = 46, 139, 87
    Seagull                = 140, 190, 214
    SealBrown              = 61, 12, 2
    Seance                 = 96, 47, 107
    SeaPink                = 215, 131, 127
    SeaShell               = 255, 245, 238
    Selago                 = 250, 230, 250
    SelectiveYellow        = 242, 180, 0
    SemiSweetChocolate     = 107, 68, 35
    Sepia                  = 150, 90, 62
    Serenade               = 255, 233, 209
    Shadow                 = 133, 109, 77
    Shakespeare            = 114, 160, 193
    Shalimar               = 252, 255, 164
    Shamrock               = 68, 215, 168
    ShamrockGreen          = 0, 153, 102
    SherpaBlue             = 0, 75, 73
    SherwoodGreen          = 27, 77, 62
    Shilo                  = 222, 165, 164
    ShipCove               = 119, 139, 165
    Shocking               = 241, 156, 187
    ShockingPink           = 255, 29, 206
    ShuttleGrey            = 84, 98, 111
    Sidecar                = 238, 224, 177
    Sienna                 = 160, 82, 45
    Silk                   = 190, 164, 147
    Silver                 = 192, 192, 192
    SilverChalice          = 175, 177, 174
    SilverTree             = 102, 201, 146
    SkyBlue                = 135, 206, 235
    SlateBlue              = 106, 90, 205
    SlateGray              = 112, 128, 144
    SlateGrey              = 112, 128, 144
    Smalt                  = 0, 48, 143
    SmaltBlue              = 74, 100, 108
    Snow                   = 255, 250, 250
    SoftAmber              = 209, 190, 168
    Solitude               = 235, 236, 240
    Sorbus                 = 233, 105, 44
    Spectra                = 53, 101, 77
    SpicyMix               = 136, 101, 78
    Spray                  = 126, 212, 230
    SpringBud              = 150, 255, 0
    SpringGreen            = 0, 255, 127
    SpringSun              = 236, 235, 189
    SpunPearl              = 170, 169, 173
    Stack                  = 130, 142, 132
    SteelBlue              = 70, 130, 180
    Stiletto               = 137, 63, 69
    Strikemaster           = 145, 92, 131
    StTropaz               = 50, 82, 123
    Studio                 = 115, 79, 150
    Sulu                   = 201, 220, 135
    SummerSky              = 33, 171, 205
    Sun                    = 237, 135, 45
    Sundance               = 197, 179, 88
    Sunflower              = 228, 208, 10
    Sunglow                = 255, 204, 51
    SunsetOrange           = 253, 82, 64
    SurfieGreen            = 0, 116, 116
    Sushi                  = 111, 153, 64
    SuvaGrey               = 140, 140, 140
    Swamp                  = 35, 43, 43
    SweetCorn              = 253, 219, 109
    SweetPink              = 243, 153, 152
    Tacao                  = 236, 177, 118
    TahitiGold             = 235, 97, 35
    Tan                    = 210, 180, 140
    Tangaroa               = 0, 28, 61
    Tangerine              = 228, 132, 0
    TangerineYellow        = 253, 204, 13
    Tapestry               = 183, 110, 121
    Taupe                  = 72, 60, 50
    TaupeGrey              = 139, 133, 137
    TawnyPort              = 102, 66, 77
    TaxBreak               = 79, 102, 106
    TeaGreen               = 208, 240, 192
    Teak                   = 176, 141, 87
    Teal                   = 0, 128, 128
    TeaRose                = 255, 133, 207
    Temptress              = 60, 20, 33
    Tenne                  = 200, 101, 0
    TerraCotta             = 226, 114, 91
    Thistle                = 216, 191, 216
    TickleMePink           = 245, 111, 161
    Tidal                  = 232, 244, 140
    TitanWhite             = 214, 202, 221
    Toast                  = 165, 113, 100
    Tomato                 = 255, 99, 71
    TorchRed               = 255, 3, 62
    ToryBlue               = 54, 81, 148
    Tradewind              = 110, 174, 161
    TrendyPink             = 133, 96, 136
    TropicalRainForest     = 0, 127, 102
    TrueV                  = 139, 114, 190
    TulipTree              = 229, 183, 59
    Tumbleweed             = 222, 170, 136
    Turbo                  = 255, 195, 36
    TurkishRose            = 152, 119, 123
    Turquoise              = 64, 224, 208
    TurquoiseBlue          = 118, 215, 234
    Tuscany                = 175, 89, 62
    TwilightBlue           = 253, 255, 245
    Twine                  = 186, 135, 89
    TyrianPurple           = 102, 2, 60
    Ultramarine            = 10, 17, 149
    UltraPink              = 255, 111, 255
    Valencia               = 222, 82, 70
    VanCleef               = 84, 61, 55
    VanillaIce             = 229, 204, 201
    VenetianRed            = 209, 0, 28
    Venus                  = 138, 127, 128
    Vermilion              = 251, 79, 20
    VeryLightGrey          = 207, 207, 207
    VidaLoca               = 94, 140, 49
    Viking                 = 71, 171, 204
    Viola                  = 180, 131, 149
    ViolentViolet          = 50, 23, 77
    Violet                 = 238, 130, 238
    VioletRed              = 255, 57, 136
    Viridian               = 64, 130, 109
    VistaBlue              = 159, 226, 191
    VividViolet            = 127, 62, 152
    WaikawaGrey            = 83, 104, 149
    Wasabi                 = 150, 165, 60
    Watercourse            = 0, 106, 78
    Wedgewood              = 67, 107, 149
    WellRead               = 147, 61, 65
    Wewak                  = 255, 152, 153
    Wheat                  = 245, 222, 179
    Whiskey                = 217, 154, 108
    WhiskeySour            = 217, 144, 88
    White                  = 255, 255, 255
    WhiteSmoke             = 245, 245, 245
    WildRice               = 228, 217, 111
    WildSand               = 229, 228, 226
    WildStrawberry         = 252, 65, 154
    WildWatermelon         = 255, 84, 112
    WildWillow             = 172, 191, 96
    Windsor                = 76, 40, 130
    Wisteria               = 191, 148, 228
    Wistful                = 162, 162, 208
    Yellow                 = 255, 255, 0
    YellowGreen            = 154, 205, 50
    YellowOrange           = 255, 174, 66
    YourPink               = 244, 194, 194
}
$Script:ScriptBlockColors = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Script:RGBColors.Keys | Where-Object { $_ -like "*$wordToComplete*" }
}
# Validation for Actions
$Script:PDFAction = {
    ([iText.Kernel.Pdf.Action.PdfAction] | Get-Member -Static -MemberType Property).Name
}
$Script:PDFActionValidation = {
    $Array = @(
        (& $Script:PDFAction)
        ''
    )
    $_ -in $Array
}

function Get-PDFConstantAction {
    [CmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFActionValidation } )][string] $Action
    )
    return [iText.Kernel.Pdf.Action.PdfAction]::$Action
}

Register-ArgumentCompleter -CommandName Get-PDFConstantAction -ParameterName Action -ScriptBlock $Script:PDFAction
# Validation for Colors
$Script:PDFColor = {
    ([iText.Kernel.Colors.ColorConstants] | Get-Member -Static -MemberType Property).Name
}
$Script:PDFColorValidation = {
    $Array = @(
        (& $Script:PDFColor)
        ''
    )
    $_ -in $Array
}

function Get-PDFConstantColor {
    [CmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFColorValidation } )][string] $Color
    )
    return [iText.Kernel.Colors.ColorConstants]::$Color
}

Register-ArgumentCompleter -CommandName Get-PDFConstantColor -ParameterName Color -ScriptBlock $Script:PDFColor
function Get-PDFConstantFont {
    [CmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFFontValidation } )][string] $Font
    )
    return [iText.IO.Font.Constants.StandardFonts]::$Font
}

Register-ArgumentCompleter -CommandName Get-PDFConstantFont -ParameterName Font -ScriptBlock $Script:PDFFont
# Validation for PageSize
$Script:PDFPageSize = {
    ([iText.Kernel.Geom.PageSize] | Get-Member -Static -MemberType Property).Name
}
$Script:PDFPageSizeValidation = {
    # Empty element is added to allow no parameter value
    $Array = @(
        (& $Script:PDFPageSize)
        ''
    )
    $_ -in $Array
}

function Get-PDFConstantPageSize {
    [CmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFPageSizeValidation } )][string] $PageSize,
        [switch] $All
    )
    if (-not $All) {
        return [iText.Kernel.Geom.PageSize]::$PageSize
    } else {
        return & $Script:PDFPageSize
    }
}

Register-ArgumentCompleter -CommandName Get-PDFConstantPageSize  -ParameterName Version -ScriptBlock $Script:PDFPageSize
# Validation for Fonts
$Script:PDFVersion = {
    ([iText.Kernel.Pdf.PdfVersion] | Get-Member -Static -MemberType Property).Name
}
$Script:PDFVersionValidation = {
    $Array = @(
        (& $Script:PDFVersion)
        ''
    )
    $_ -in $Array
}

function Get-PDFConstantVersion {
    [CmdletBinding()]
    param(
        [ValidateScript( { & $Script:PDFVersionValidation } )][string] $Version
    )
    return [iText.Kernel.Pdf.PdfVersion]::$Version
}

Register-ArgumentCompleter -CommandName Get-PDFConstantVersion -ParameterName Version -ScriptBlock $Script:PDFVersion
function Convert-HTMLToPDF {
    <#
    .SYNOPSIS
    Converts HTML to PDF.

    .DESCRIPTION
    Converts HTML to PDF from one of three sources:
    1. A file on the local file system.
    2. A URL.
    3. A string of HTML.

    .PARAMETER Uri
    The URI of the HTML to convert.

    .PARAMETER Content
    The HTML (as a string) to convert.

    .PARAMETER FilePath
    The path to the file containing the HTML to convert.

    .PARAMETER OutputFilePath
    The path to the file to write the PDF to.

    .PARAMETER Open
    If true, opens the PDF after it is created.

    .EXAMPLE
    Convert-HTMLToPDF -Uri 'https://evotec.xyz/hub/scripts/pswritehtml-powershell-module/' -OutputFilePath "$PSScriptRoot\Example10-FromURL.pdf" -Open

    .EXAMPLE
    $HTMLInput = New-HTML {
        New-HTMLText -Text 'Test 1'
        New-HTMLTable -DataTable (Get-Process | Select-Object -First 3)
    }

    Convert-HTMLToPDF -Content $HTMLInput -OutputFilePath "$PSScriptRoot\Example10-FromHTML.pdf" -Open

    .EXAMPLE
    New-HTML {
        New-HTMLTable -DataTable (Get-Process | Select-Object -First 3)
    } -FilePath "$PSScriptRoot\Example10-FromFilePath.html" -Online

    Convert-HTMLToPDF -FilePath "$PSScriptRoot\Example10-FromFilePath.html" -OutputFilePath "$PSScriptRoot\Example10-FromFilePath.pdf" -Open

    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName = 'Uri')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Uri')][alias('Url')][string] $Uri,
        [Parameter(Mandatory, ParameterSetName = 'Content')][string] $Content,
        [Parameter(Mandatory, ParameterSetName = 'FilePath')][string] $FilePath,
        [Parameter(Mandatory)][string] $OutputFilePath,
        [switch] $Open
    )
    # Load from file or text
    if ($FilePath) {
        if (Test-Path -LiteralPath $FilePath) {
            $Content = [IO.File]::ReadAllText($FilePath)
        } else {
            Write-Warning "Convert-HTMLToPDF - File $FilePath doesn't exists"
            return
        }
    } elseif ($Content) {

    } elseif ($Uri) {
        $ProgressPreference = 'SilentlyContinue'
        $Content = (Invoke-WebRequest -Uri $Uri).Content
    } else {
        Write-Warning 'Convert-HTMLToPDF - No choice file or content or url. Termninated.'
        return
    }
    if (-not $Content) {
        return
    }

    $OutputFile = [System.IO.FileInfo]::new($OutputFilePath)
    <#
    static void ConvertToPdf(string html, System.IO.Stream pdfStream)
    static void ConvertToPdf(string html, System.IO.Stream pdfStream, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(string html, iText.Kernel.Pdf.PdfWriter pdfWriter)
    static void ConvertToPdf(string html, iText.Kernel.Pdf.PdfWriter pdfWriter, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(string html, iText.Kernel.Pdf.PdfDocument pdfDocument, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(System.IO.FileInfo htmlFile, System.IO.FileInfo pdfFile)
    static void ConvertToPdf(System.IO.FileInfo htmlFile, System.IO.FileInfo pdfFile, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(System.IO.Stream htmlStream, System.IO.Stream pdfStream)
    static void ConvertToPdf(System.IO.Stream htmlStream, System.IO.Stream pdfStream, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(System.IO.Stream htmlStream, iText.Kernel.Pdf.PdfDocument pdfDocument)
    static void ConvertToPdf(System.IO.Stream htmlStream, iText.Kernel.Pdf.PdfWriter pdfWriter)
    static void ConvertToPdf(System.IO.Stream htmlStream, iText.Kernel.Pdf.PdfWriter pdfWriter, iText.Html2pdf.ConverterProperties converterProperties)
    static void ConvertToPdf(System.IO.Stream htmlStream, iText.Kernel.Pdf.PdfDocument pdfDocument, iText.Html2pdf.ConverterProperties converterProperties)
    #>
    try {
        [iText.Html2pdf.HtmlConverter]::ConvertToPdf($Content, $OutputFile)
    } catch {
        Write-Warning "Convert-HTMLToPDF - Error converting to PDF. Error: $($_.Exception.Message)"
        return
    }
    if ($Open) {
        Start-Process -FilePath $OutputFilePath -Wait
    }
}
function Convert-PDFToText {
    <#
    .SYNOPSIS
    Converts PDF to TEXT

    .DESCRIPTION
    Converts PDF to TEXT

    .PARAMETER FilePath
    The path to the PDF file to convert

    .PARAMETER Page
    The page number to convert (default is all pages)

    .PARAMETER ExtractionStrategy
    The iText Extractiostrategey that is used to parse the text. Currently supports LocationTextExtractionStrategy (LT) and SimpleTextExtractionStrategy (ST)(Default).
    
    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    # Get all pages text
    Convert-PDFToText -FilePath "$PSScriptRoot\Example04.pdf"
    
    .EXAMPLE
    # Get all pages text with Location-Extractionstrategy
    Convert-PDFToText -FilePath "$PSScriptRoot\Example04.pdf" -ExtractionStrategy "LT"

    .EXAMPLE
    # Get page 1 text only
    Convert-PDFToText -FilePath "$PSScriptRoot\Example04.pdf" -Page 1

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [int[]] $Page,
        [ValidateSet("SimpleTextExtractionStrategy", "LocationTextExtractionStrategy", "ST", "LT")]
        [string] $ExtractionStrategy = "SimpleTextExtractionStrategy",
        [switch] $IgnoreProtection
    )
    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $ResolvedPath = Convert-Path -LiteralPath $FilePath
        $Source = [iText.Kernel.Pdf.PdfReader]::new($ResolvedPath)
        if ($IgnoreProtection) {
            $null = $Source.SetUnethicalReading($true)
        }
        try {
            [iText.Kernel.Pdf.PdfDocument] $SourcePDF = [iText.Kernel.Pdf.PdfDocument]::new($Source);
            if ($ExtractionStrategy -eq "SimpleTextExtractionStrategy" -or $ExtractionStrategy -eq "ST") {
                [iText.Kernel.Pdf.Canvas.Parser.Listener.SimpleTextExtractionStrategy] $iTextExtractionStrategy = [iText.Kernel.Pdf.Canvas.Parser.Listener.SimpleTextExtractionStrategy]::new()
            } elseif ($ExtractionStrategy -eq "LocationTextExtractionStrategy" -or $ExtractionStrategy -eq "LT") {
                [iText.Kernel.Pdf.Canvas.Parser.Listener.LocationTextExtractionStrategy] $iTextExtractionStrategy = [iText.Kernel.Pdf.Canvas.Parser.Listener.LocationTextExtractionStrategy]::new()
            }
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Convert-PDFToText - Processing document $ResolvedPath failed with error: $ErrorMessage"
        }

        $PagesCount = $SourcePDF.GetNumberOfPages()
        if ($Page.Count -eq 0) {
            for ($Count = 1; $Count -le $PagesCount; $Count++) {
                try {
                    $ExtractedPage = $SourcePDF.GetPage($Count)
                    [iText.Kernel.Pdf.Canvas.Parser.PdfTextExtractor]::GetTextFromPage($ExtractedPage, $iTextExtractionStrategy)
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning "Convert-PDFToText - Processing document $ResolvedPath failed with error: $ErrorMessage"
                }
            }
        } else {
            foreach ($Count in $Page) {
                if ($Count -le $PagesCount -and $Count -gt 0) {
                    try {
                        $ExtractedPage = $SourcePDF.GetPage($Count)
                        [iText.Kernel.Pdf.Canvas.Parser.PdfTextExtractor]::GetTextFromPage($ExtractedPage, $iTextExtractionStrategy)
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Warning "Convert-PDFToText - Processing document $ResolvedPath failed with error: $ErrorMessage"
                    }
                } else {
                    Write-Warning "Convert-PDFToText - File $ResolvedPath doesn't contain page number $Count. Skipping."
                }
            }
        }
        try {
            $SourcePDF.Close()
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Convert-PDFToText - Closing document $FilePath failed with error: $ErrorMessage"
        }
    } else {
        Write-Warning "Convert-PDFToText - Path $FilePath doesn't exists. Terminating."
    }
}

function Merge-PDF {
    <#
    .SYNOPSIS
    Merge PDF files into one.

    .DESCRIPTION
    Merge PDF files into one.

    .PARAMETER InputFile
    The PDF files to be merged.

    .PARAMETER OutputFile
    The output file path.

    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    $FilePath1 = "$PSScriptRoot\Input\OutputDocument0.pdf"
    $FilePath2 = "$PSScriptRoot\Input\OutputDocument1.pdf"

    $OutputFile = "$PSScriptRoot\Output\OutputDocument.pdf" # Shouldn't exist / will be overwritten

    Merge-PDF -InputFile $FilePath1, $FilePath2 -OutputFile $OutputFile

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string[]] $InputFile,
        [string] $OutputFile,
        [switch] $IgnoreProtection
    )

    if ($OutputFile) {
        try {
            [iText.Kernel.Pdf.PdfWriter] $Writer = [iText.Kernel.Pdf.PdfWriter]::new($OutputFile)
            [iText.Kernel.Pdf.PdfDocument] $PDF = [iText.Kernel.Pdf.PdfDocument]::new($Writer);
            [iText.Kernel.Utils.PdfMerger] $Merger = [iText.Kernel.Utils.PdfMerger]::new($PDF)
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Merge-PDF - Processing document $OutputFile failed with error: $ErrorMessage"
        }
        foreach ($File in $InputFile) {
            if ($File -and (Test-Path -LiteralPath $File)) {
                $ResolvedFile = Convert-Path -LiteralPath $File
                try {
                    $Source = [iText.Kernel.Pdf.PdfReader]::new($ResolvedFile)
                    if ($IgnoreProtection) {
                        $null = $Source.SetUnethicalReading($true)
                    }
                    [iText.Kernel.Pdf.PdfDocument] $SourcePDF = [iText.Kernel.Pdf.PdfDocument]::new($Source);
                    $null = $Merger.merge($SourcePDF, 1, $SourcePDF.getNumberOfPages())
                    $SourcePDF.close()
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning "Merge-PDF - Processing document $ResolvedFile failed with error: $ErrorMessage"
                }
            }
        }
        try {
            $PDF.Close()
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Merge-PDF - Saving document $OutputFile failed with error: $ErrorMessage"
        }
    } else {
        Write-Warning "Merge-PDF - Output file was empty. Please give a name to file. Terminating."
    }
}
function Set-PDFForm {
    <#
    .SYNOPSIS
    Will try to fill form fields in source PDF with values from hash table.
    Can also flatten the form to prevent changes with -flatten.

    .DESCRIPTION
    Adds a file name extension to a supplied name.
    Takes any strings for the file name or extension.

    .PARAMETER SourceFilePath
    Specifies the to be filled in PDF Form.

    .PARAMETER DestinationFilePath
    Specifies the output filepath for the completed form.

    .PARAMETER FieldNameAndValueHashTable
    Specifies the hashtable for the fields data. Key in the hashtable needs to match the feild name in the PDF.

    .PARAMETER Flatten
    Will flatten the output PDF so form fields will no longer be able to be changed.

    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    $FilePath = [IO.Path]::Combine("$PSScriptRoot", "Output", "SampleAcroFormOutput.pdf")
    $FilePathSource = [IO.Path]::Combine("$PSScriptRoot", "Input", "SampleAcroForm.pdf")

    $FieldNameAndValueHashTable = [ordered] @{
        "Text 1" = "Text 1 input"
        "Text 2" = "Text 2 input"
        "Text 3" = "Text 3 input"
        "Check Box 1 True" = $true
        "Check Box 2 False" = $false
        "Check Box 3 False" = $false
        "Check Box 4 True" = $true
        "Doesn't Exist" = "will not be used"
    }
    Set-PDFForm -SourceFilePath $FilePathSource -DestinationFilePath $FilePath -FieldNameAndValueHashTable $FieldNameAndValueHashTable -Flatten

    .EXAMPLE
    $FilePath = [IO.Path]::Combine("$PSScriptRoot", "Output", "SampleAcroFormOutput.pdf")
    $FilePathSource = [IO.Path]::Combine("$PSScriptRoot", "Input", "SampleAcroForm.pdf")
    Set-PDFForm -SourceFilePath $FilePathSource -DestinationFilePath $FilePath -Flatten

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()] $SourceFilePath,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()] $DestinationFilePath,
        [System.Collections.IDictionary] $FieldNameAndValueHashTable,
        [alias('FlattenFields')][Switch] $Flatten,
        [switch] $IgnoreProtection
    )
    $SourceFilePath = Convert-Path -LiteralPath $SourceFilePath
    $DestinationFolder = Split-Path -LiteralPath $DestinationFilePath
    $DestinationFolderPath = Convert-Path -LiteralPath $DestinationFolder -ErrorAction SilentlyContinue

    if ($DestinationFolderPath -and (Test-Path -LiteralPath $SourceFilePath) -and (Test-Path -LiteralPath $DestinationFolderPath)) {
        $File = Split-Path -Path $DestinationFilePath -Leaf
        $DestinationFilePath = Join-Path -Path $DestinationFolderPath -ChildPath $File

        try {
            $Script:Reader = [iText.Kernel.Pdf.PdfReader]::new($SourceFilePath)
            if ($IgnoreProtection) {
                $null = $Script:Reader.SetUnethicalReading($true)
            }
            $Script:Writer = [iText.Kernel.Pdf.PdfWriter]::new($DestinationFilePath)
            $PDF = [iText.Kernel.Pdf.PdfDocument]::new($Script:Reader, $Script:Writer)
            $PDFAcroForm = [iText.Forms.PdfAcroForm]::getAcroForm($PDF, $true)
        } catch {
            Write-Warning "Set-PDFForm - Error has occured: $($_.Exception.Message)"
        }
        foreach ($Key in $FieldNameAndValueHashTable.Keys) {
            $FormField = $PDFAcroForm.getField($Key)
            if ( -not $FormField) {
                Write-Warning "Set-PDFForm - No form field with name '$Key' found"
                continue
            }

            if ($FormField.GetType().Name -match "Button") {
                $null = $FormField.setValue(
                    $FormField.GetAppearanceStates()[[Int]$FieldNameAndValueHashTable[$Key]]
                )
            } else {
                $null = $FormField.setValue($FieldNameAndValueHashTable[$Key])
            }
        }

        if ($Flatten) {
            $PDFAcroForm.flattenFields()
        }

        try {
            $PDF.Close()
        } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                Write-Error $_
                return
            } else {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Set-PDFForm - Error has occured: $ErrorMessage"
            }
        }
    } else {
        if (-not (Test-Path -LiteralPath $SourceFilePath)) {
            Write-Warning "Set-PDFForm - Path $SourceFilePath doesn't exists. Terminating."
        }

        if (-not (Test-Path -LiteralPath $DestinationFolder)) {
            Write-Warning "Set-PDFForm - Folder $DestinationFolder doesn't exists. Terminating."
        }
    }
}

function Split-PDF {
    <#
    .SYNOPSIS
    Split PDF file into multiple files.

    .DESCRIPTION
    Split PDF file into multiple files. The output files will be named based on OutputName variable with appended numbers

    .PARAMETER FilePath
    The path to the PDF file to split.

    .PARAMETER OutputFolder
    The folder to output the split files to.

    .PARAMETER OutputName
    The name of the output files. Default is OutputDocument

    .PARAMETER SplitCount
    The number of pages to split the PDF file into. Default is 1

    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    Split-PDF -FilePath "$PSScriptRoot\SampleToSplit.pdf" -OutputFolder "$PSScriptRoot\Output"

    .EXAMPLE
    Split-PDF -FilePath "\\ad1\c$\SampleToSplit.pdf" -OutputFolder "\\ad1\c$\Output"

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [Parameter(Mandatory)][string] $OutputFolder,
        [string] $OutputName = 'OutputDocument',
        [int] $SplitCount = 1,
        [switch] $IgnoreProtection
    )
    if ($SplitCount -eq 0) {
        Write-Warning "Split-PDF - SplitCount is 0. Terminating."
        return
    }

    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $ResolvedPath = Convert-Path -LiteralPath $FilePath
        if ($OutputFolder -and (Test-Path -LiteralPath $OutputFolder)) {
            try {
                $PDFFile = [iText.Kernel.Pdf.PdfReader]::new($ResolvedPath)
                if ($IgnoreProtection) {
                    $null = $PDFFile.SetUnethicalReading($true)
                }
                $Document = [iText.Kernel.Pdf.PdfDocument]::new($PDFFile)
                $Splitter = [CustomSplitter]::new($Document, $OutputFolder, $OutputName)
                $List = $Splitter.SplitByPageCount($SplitCount)
                foreach ($_ in $List) {
                    $_.Close()
                }
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Split-PDF - Error has occured: $ErrorMessage"
            }
            try {
                $PDFFile.Close()
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "Split-PDF - Closing document $FilePath failed with error: $ErrorMessage"
            }
        } else {
            Write-Warning "Split-PDF - Destination folder $OutputFolder doesn't exists. Terminating."
        }
    } else {
        Write-Warning "Split-PDF - Path $FilePath doesn't exists. Terminating."
    }
}
function Close-PDF {
    [CmdletBinding()]
    param(
        [iText.Kernel.Pdf.PdfDocument] $Document
    )
    if ($Document) {
        $Document.Close()
    }
}
function Get-PDF {
    <#
    .SYNOPSIS
    Gets PDF file and returns it as an PDF object

    .DESCRIPTION
    Gets PDF file and returns it as an PDF object

    .PARAMETER FilePath
    Path to the PDF file to be processed

    .PARAMETER IgnoreProtection
    The switch will allow reading of PDF files that are "owner password" encrypted for protection/security (e.g. preventing copying of text, printing etc).
    The switch doesn't allow reading of PDF files that are "user password" encrypted (i.e. you cannot open them without the password)

    .EXAMPLE
    $Document = Get-PDF -FilePath "C:\Users\przemyslaw.klys\OneDrive - Evotec\Support\GitHub\PSWritePDF\Example\Example01.HelloWorld\Example01_WithSectionsMix.pdf"
    $Details = Get-PDFDetails -Document $Document
    $Details | Format-List
    $Details.Pages | Format-Table

    Close-PDF -Document $Document

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $FilePath,
        [switch] $IgnoreProtection
    )

    if ($FilePath -and (Test-Path -LiteralPath $FilePath)) {
        $ResolvedPath = Convert-Path -LiteralPath $FilePath

        try {
            $PDFFile = [iText.Kernel.Pdf.PdfReader]::new($ResolvedPath)
            if ($IgnoreProtection) {
                $null = $PDFFile.SetUnethicalReading($true)
            }
            $Document = [iText.Kernel.Pdf.PdfDocument]::new($PDFFile)
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Get-PDF - Processing document $FilePath failed with error: $ErrorMessage"
        }
        $Document

    }
}
function Get-PDFDetails {
    [CmdletBinding()]
    param(
        [iText.Kernel.Pdf.PdfDocument] $Document
    )
    if ($Document) {
        [iText.Layout.Document] $LayoutDocument = [iText.Layout.Document]::new($Document)

        $Output = [ordered] @{
            Author       = $Document.GetDocumentInfo().GetAuthor()
            Creator      = $Document.GetDocumentInfo().GetCreator()
            HashCode     = $Document.GetDocumentInfo().GetHashCode()
            Keywords     = $Document.GetDocumentInfo().GetKeywords()
            Producer     = $Document.GetDocumentInfo().GetProducer()
            Subject      = $Document.GetDocumentInfo().GetSubject()
            Title        = $Document.GetDocumentInfo().GetTitle()
            Trapped      = $Document.GetDocumentInfo().GetTrapped()
            Version      = $Document.GetPdfVersion()
            PagesNumber  = $Document.GetNumberOfPages()
            MarginLeft   = $LayoutDocument.GetLeftMargin()
            MarginRight  = $LayoutDocument.GetRightMargin()
            MarginBottom = $LayoutDocument.GetBottomMargin()
            MarginTop    = $LayoutDocument.GetTopMargin()
            Pages        = [ordered] @{ }
        }
        for ($a = 1; $a -le $Output.PagesNumber; $a++) {
            $Height = $Document.GetPage($a).GetPageSizeWithRotation().GetHeight()
            $Width = $Document.GetPage($a).GetPageSizeWithRotation().GetWidth()
            $NamedSize = Get-PDFNamedPageSize -Height $Height -Width $Width
            $Output['Pages']["$a"] = [PSCustomObject] @{
                Height   = $Height
                Width    = $Width
                Rotation = $Document.GetPage($a).GetRotation()
                Size     = $NamedSize.PageSize
                Rotated  = $NamedSize.Rotated
            }
        }
        [PSCustomObject] $Output
    }
}
function Get-PDFFormField {
    [CmdletBinding()]
    param(
        [iText.Kernel.Pdf.PdfDocument]$PDF
    )
    try {
        $PDFAcroForm = [iText.Forms.PdfAcroForm]::getAcroForm($PDF, $true)
        $PDFAcroForm.GetFormFields()
    } catch {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            Write-Error $_
            return
        } else {
            Write-Warning -Message "Get-PDFFormField - There was an error reading forms or no form exists. Exception: $($_.Error.Exception)"
        }
    }
}
function New-PDF {
    [CmdletBinding()]
    param(
        [scriptblock] $PDFContent,
        [Parameter(Mandatory)][string] $FilePath,
        [string] $Version,

        [nullable[float]] $MarginLeft,
        [nullable[float]] $MarginRight,
        [nullable[float]] $MarginTop,
        [nullable[float]] $MarginBottom,
        [ValidateScript( { & $Script:PDFPageSizeValidation } )][string] $PageSize,
        [switch] $Rotate,

        [alias('Open')][switch] $Show
    )
    # The types needs filling in for the workaround below. DONT FORGET!
    $Script:Types = 'Text', 'List', 'Paragraph', 'Table', 'Image'
    $Script:PDFStart = @{
        Start            = $true
        FilePath         = $FilePath
        DocumentSettings = @{
            MarginTop    = $MarginTop
            MarginBottom = $MarginBottom
            MarginLeft   = $MarginLeft
            MarginRight  = $MarginRight
            PageSize     = $PageSize
            Rotate       = $Rotate.IsPresent
        }
        FirstPageFound   = $false
        FirstPageUsed    = $false
        UsedTypes        = [System.Collections.Generic.List[string]]::new()
    }
    if ($PDFContent) {
        [Array] $Elements = @(
            [Array] $Content = & $PDFContent
            # This is workaround to support multiple scenarios:
            # New-PDF { New-PDFPage, New-PDFPage }
            # New-PDF { }
            # New-PDF { New-PDFText, New-PDFPage }
            # This is there to make sure we allow for New-PDF to allow control for -Rotate/PageSize to either whole document or to text/tables
            # and other types until New-PDFPage is given
            # It's ugly but seems to wrok
            foreach ($_ in $Content) {
                if ($_.Type -in $Script:Types) {
                    $Script:PDFStart.UsedTypes.Add($_.Type)
                } elseif ($_.Type -eq 'Page') {
                    if ($Script:PDFStart.UsedTypes.Count -ne 0) {
                        New-PDFPage -PageSize $PageSize -Rotate:$Rotate -MarginLeft $MarginLeft -MarginTop $MarginTop -MarginBottom $MarginBottom -MarginRight $MarginRight
                        $Script:PDFStart.FirstPageFound = $true
                    }
                    break
                }
            }
            if (-not $Script:PDFStart.FirstPageFound -and $Script:PDFStart.UsedTypes.Count -ne 0) {
                New-PDFPage -PageSize $PageSize -Rotate:$Rotate -MarginLeft $MarginLeft -MarginTop $MarginTop -MarginBottom $MarginBottom -MarginRight $MarginRight
                $Script:PDFStart.FirstPageFound = $true
            }
            $Content
        )
        if ($Elements) {
            $Script:PDF = New-InternalPDF -FilePath $FilePath -Version $Version #-PageSize $PageSize -Rotate:$Rotate
            if (-not $Script:PDF) {
                return
            }
        } else {
            Write-Warning "New-PDF - No content was provided. Terminating."
            return
        }
    } else {
        $Script:PDFStart['Start'] = $false
        # if there's no scriptblock that means we're using standard way of working with PDF
        $Script:PDF = New-InternalPDF -FilePath $FilePath -Version $Version #-PageSize $PageSize -Rotate:$Rotate
        return $Script:PDF
    }

    $Script:PDFStart['Start'] = $true
    #[iText.Layout.Document] $Script:Document = New-PDFDocument -PDF $Script:PDF
    #New-InternalPDFOptions -MarginLeft $MarginLeft -MarginRight $MarginRight -MarginTop $MarginTop -MarginBottom $MarginBottom

    Initialize-PDF -Elements $Elements
    if ($Script:Document) {
        $Script:Document.Close();
    }
    if ($Show) {
        if (Test-Path -LiteralPath $FilePath) {
            Invoke-Item -LiteralPath $FilePath
        }
    }
    $Script:PDFStart = $null
    #$Script:PDFStart['Start'] = $false
}

Register-ArgumentCompleter -CommandName New-PDF -ParameterName PageSize -ScriptBlock $Script:PDFPageSize
Register-ArgumentCompleter -CommandName New-PDF -ParameterName Version -ScriptBlock $Script:PDFVersion
function New-PDFArea {
    [CmdletBinding()]
    param(
        [iText.Layout.Properties.AreaBreakType] $AreaType = [iText.Layout.Properties.AreaBreakType]::NEXT_AREA,
        [string] $PageSize,
        [switch] $Rotate
    )
    # https://api.itextpdf.com/iText7/dotnet/7.1.8/classi_text_1_1_kernel_1_1_geom_1_1_page_size.html
    $AreaBreak = [iText.Layout.Element.AreaBreak]::new($AreaType)
    if ($PageSize) {
        $Page = [iText.Kernel.Geom.PageSize]::($PageSize)
    } else {
        $Page = [iText.Kernel.Geom.PageSize]::Default
    }
    if ($Rotate) {
        $Page = $Page.Rotate()
    }
    $AreaBreak.SetPageSize($Page)
    return $AreaBreak
}

Register-ArgumentCompleter -CommandName New-PDFArea  -ParameterName PageSize -ScriptBlock $Script:PDFPageSize

<#
   TypeName: iText.Layout.Element.AreaBreak

Name                       MemberType Definition
----                       ---------- ----------
AddStyle                   Method     iText.Layout.Element.AreaBreak AddStyle(iText.Layout.Style style)
CreateRendererSubTree      Method     iText.Layout.Renderer.IRenderer CreateRendererSubTree(), iText.Layout.Renderer.IRenderer IElement.CreateRendererSubTree()
DeleteOwnProperty          Method     void DeleteOwnProperty(int property), void IPropertyContainer.DeleteOwnProperty(int property)
Equals                     Method     bool Equals(System.Object obj)
GetAreaType                Method     System.Nullable[iText.Layout.Properties.AreaBreakType] GetAreaType()
GetChildren                Method     System.Collections.Generic.IList[iText.Layout.Element.IElement] GetChildren()
GetDefaultProperty         Method     T1 GetDefaultProperty[T1](int property), T1 IPropertyContainer.GetDefaultProperty[T1](int property)
GetHashCode                Method     int GetHashCode()
GetOwnProperty             Method     T1 GetOwnProperty[T1](int property), T1 IPropertyContainer.GetOwnProperty[T1](int property)
GetPageSize                Method     iText.Kernel.Geom.PageSize GetPageSize()
GetProperty                Method     T1 GetProperty[T1](int property), T1 IPropertyContainer.GetProperty[T1](int property)
GetRenderer                Method     iText.Layout.Renderer.IRenderer GetRenderer(), iText.Layout.Renderer.IRenderer IElement.GetRenderer()
GetSplitCharacters         Method     iText.Layout.Splitting.ISplitCharacters GetSplitCharacters()
GetStrokeColor             Method     iText.Kernel.Colors.Color GetStrokeColor()
GetStrokeWidth             Method     System.Nullable[float] GetStrokeWidth()
GetTextRenderingMode       Method     System.Nullable[int] GetTextRenderingMode()
GetType                    Method     type GetType()
HasOwnProperty             Method     bool HasOwnProperty(int property), bool IPropertyContainer.HasOwnProperty(int property)
HasProperty                Method     bool HasProperty(int property), bool IPropertyContainer.HasProperty(int property)
IsEmpty                    Method     bool IsEmpty()
SetAction                  Method     iText.Layout.Element.AreaBreak SetAction(iText.Kernel.Pdf.Action.PdfAction action)
SetBackgroundColor         Method     iText.Layout.Element.AreaBreak SetBackgroundColor(iText.Kernel.Colors.Color backgroundColor), iText.Layout.Element.AreaBreak SetBackgroun...
SetBaseDirection           Method     iText.Layout.Element.AreaBreak SetBaseDirection(System.Nullable[iText.Layout.Properties.BaseDirection] baseDirection)
SetBold                    Method     iText.Layout.Element.AreaBreak SetBold()
SetBorder                  Method     iText.Layout.Element.AreaBreak SetBorder(iText.Layout.Borders.Border border)
SetBorderBottom            Method     iText.Layout.Element.AreaBreak SetBorderBottom(iText.Layout.Borders.Border border)
SetBorderBottomLeftRadius  Method     iText.Layout.Element.AreaBreak SetBorderBottomLeftRadius(iText.Layout.Properties.BorderRadius borderRadius)
SetBorderBottomRightRadius Method     iText.Layout.Element.AreaBreak SetBorderBottomRightRadius(iText.Layout.Properties.BorderRadius borderRadius)
SetBorderLeft              Method     iText.Layout.Element.AreaBreak SetBorderLeft(iText.Layout.Borders.Border border)
SetBorderRadius            Method     iText.Layout.Element.AreaBreak SetBorderRadius(iText.Layout.Properties.BorderRadius borderRadius)
SetBorderRight             Method     iText.Layout.Element.AreaBreak SetBorderRight(iText.Layout.Borders.Border border)
SetBorderTop               Method     iText.Layout.Element.AreaBreak SetBorderTop(iText.Layout.Borders.Border border)
SetBorderTopLeftRadius     Method     iText.Layout.Element.AreaBreak SetBorderTopLeftRadius(iText.Layout.Properties.BorderRadius borderRadius)
SetBorderTopRightRadius    Method     iText.Layout.Element.AreaBreak SetBorderTopRightRadius(iText.Layout.Properties.BorderRadius borderRadius)
SetCharacterSpacing        Method     iText.Layout.Element.AreaBreak SetCharacterSpacing(float charSpacing)
SetDestination             Method     iText.Layout.Element.AreaBreak SetDestination(string destination)
SetFixedPosition           Method     iText.Layout.Element.AreaBreak SetFixedPosition(float left, float bottom, float width), iText.Layout.Element.AreaBreak SetFixedPosition(f...
SetFont                    Method     iText.Layout.Element.AreaBreak SetFont(iText.Kernel.Font.PdfFont font), iText.Layout.Element.AreaBreak SetFont(string font)
SetFontColor               Method     iText.Layout.Element.AreaBreak SetFontColor(iText.Kernel.Colors.Color fontColor), iText.Layout.Element.AreaBreak SetFontColor(iText.Kerne...
SetFontFamily              Method     iText.Layout.Element.AreaBreak SetFontFamily(Params string[] fontFamilyNames), iText.Layout.Element.AreaBreak SetFontFamily(System.Collec...
SetFontKerning             Method     iText.Layout.Element.AreaBreak SetFontKerning(iText.Layout.Properties.FontKerning fontKerning)
SetFontScript              Method     iText.Layout.Element.AreaBreak SetFontScript(System.Nullable[iText.IO.Util.UnicodeScript] script)
SetFontSize                Method     iText.Layout.Element.AreaBreak SetFontSize(float fontSize)
SetHorizontalAlignment     Method     iText.Layout.Element.AreaBreak SetHorizontalAlignment(System.Nullable[iText.Layout.Properties.HorizontalAlignment] horizontalAlignment)
SetHyphenation             Method     iText.Layout.Element.AreaBreak SetHyphenation(iText.Layout.Hyphenation.HyphenationConfig hyphenationConfig)
SetItalic                  Method     iText.Layout.Element.AreaBreak SetItalic()
SetLineThrough             Method     iText.Layout.Element.AreaBreak SetLineThrough()
SetNextRenderer            Method     void SetNextRenderer(iText.Layout.Renderer.IRenderer renderer), void IElement.SetNextRenderer(iText.Layout.Renderer.IRenderer renderer)
SetOpacity                 Method     iText.Layout.Element.AreaBreak SetOpacity(System.Nullable[float] opacity)
SetPageNumber              Method     iText.Layout.Element.AreaBreak SetPageNumber(int pageNumber)
SetPageSize                Method     void SetPageSize(iText.Kernel.Geom.PageSize pageSize)
SetProperty                Method     void SetProperty(int property, System.Object value), void IPropertyContainer.SetProperty(int property, System.Object value)
SetRelativePosition        Method     iText.Layout.Element.AreaBreak SetRelativePosition(float left, float top, float right, float bottom)
SetSplitCharacters         Method     iText.Layout.Element.AreaBreak SetSplitCharacters(iText.Layout.Splitting.ISplitCharacters splitCharacters)
SetStrokeColor             Method     iText.Layout.Element.AreaBreak SetStrokeColor(iText.Kernel.Colors.Color strokeColor)
SetStrokeWidth             Method     iText.Layout.Element.AreaBreak SetStrokeWidth(float strokeWidth)
SetTextAlignment           Method     iText.Layout.Element.AreaBreak SetTextAlignment(System.Nullable[iText.Layout.Properties.TextAlignment] alignment)
SetTextRenderingMode       Method     iText.Layout.Element.AreaBreak SetTextRenderingMode(int textRenderingMode)
SetUnderline               Method     iText.Layout.Element.AreaBreak SetUnderline(), iText.Layout.Element.AreaBreak SetUnderline(float thickness, float yPosition), iText.Layou...
SetWordSpacing             Method     iText.Layout.Element.AreaBreak SetWordSpacing(float wordSpacing)
ToString                   Method     string ToString()
#>
function New-PDFDocument {
    [CmdletBinding()]
    param(
        [iText.Kernel.Pdf.PdfDocument] $PDF
    )
    [iText.Layout.Document] $Document = [iText.Layout.Document]::new($PDF)
    return $Document
}
function New-PDFImage {
    [CmdletBinding()]
    param(
        [string] $ImagePath,
        [int] $Width,
        [int] $Height,
        [string] $BackgroundColor,
        [double] $BackgroundColorOpacity
    )

    [PSCustomObject] @{
        Type     = 'Image'
        Settings = @{
            ImagePath              = $ImagePath
            Width                  = $Width
            Height                 = $Height
            BackgroundColor        = ConvertFrom-Color -Color $BackgroundColor -AsDrawingColor
            BackgroundColorOpacity = $BackgroundColorOpacity
        }
    }
}

Register-ArgumentCompleter -CommandName New-PDFImage -ParameterName BackgroundColor -ScriptBlock $Script:ScriptBlockColors
function New-PDFInfo {
    [CmdletBinding()]
    param(
        [iText.Kernel.Pdf.PdfDocument] $PDF,
        [string] $Title,
        [string] $Author,
        [string] $Creator,
        [string] $Subject,
        [string[]] $Keywords,
        [switch] $AddCreationDate,
        [switch] $AddModificationDate
    )

    try {
        [iText.Kernel.Pdf.PdfDocumentInfo] $info = $pdf.GetDocumentInfo()
    } catch {
        Write-Warning "New-PDFInfo - Error: $($_.Exception.Message)"
        return
    }

    if ($Title) {
        $null = $info.SetTitle($Title)
    }
    if ($AddCreationDate) {
        $null = $info.AddCreationDate()
    }
    if ($AddModificationDate) {
        $null = $info.AddModDate()
    }
    if ($Author) {
        $null = $info.SetAuthor($Author)
    }
    if ($Creator) {
        $null = $info.SetCreator($Creator)
    }
    if ($Subject) {
        $null = $info.SetSubject($Subject)
    }
    if ($Keywords) {
        $KeywordsString = $Keywords -join ','
        $null = $info.SetKeywords($KeywordsString)
    }
}
function New-PDFList {
    [CmdletBinding()]
    param(
        [ScriptBlock] $ListItems,
        [nullable[float]] $Indent,
        [ValidateSet('bullet', 'hyphen')][string] $Symbol = 'hyphen'
    )

    $Output = & $ListItems
    $Items = foreach ($_ in $Output) {
        if ($_.Type -eq 'ListItem') {
            $_.Settings
        }
    }

    [PSCustomObject] @{
        Type     = 'List'
        Settings = @{
            Items  = $Items
            Indent = $Indent
            Symbol = $Symbol
        }
    }
}
function New-PDFListItem {
    [CmdletBinding()]
    param(
        [string[]] $Text,
        [ValidateScript( { & $Script:PDFFontValidationList } )][string[]] $Font,
        [ValidateScript( { & $Script:PDFColorValidation } )][string[]] $FontColor,
        [nullable[bool][]] $FontBold
    )

    $Splat = @{ }
    if ($Text) {
        $Splat['Text'] = $Text
    }
    if ($Font) {
        $Splat['Font'] = $Font
    }
    if ($FontColor) {
        $Splat['FontColor'] = $FontColor
    }
    if ($FontBold) {
        $Splat['FontBold'] = $FontBold
    }

    [PSCustomObject] @{
        Type     = 'ListItem'
        Settings = $Splat
    }
}

Register-ArgumentCompleter -CommandName New-PDFListItem -ParameterName Font -ScriptBlock $Script:PDFFontList
Register-ArgumentCompleter -CommandName New-PDFListItem -ParameterName FontColor -ScriptBlock $Script:PDFColor
function New-PDFOptions {
    [CmdletBinding()]
    param(
        [nullable[float]] $MarginLeft,
        [nullable[float]] $MarginRight,
        [nullable[float]] $MarginTop,
        [nullable[float]] $MarginBottom
        #[ValidateScript( { & $Script:PDFPageSizeValidation } )][string] $PageSize
    )

    [PSCustomObject] @{
        Type     = 'Options'
        Settings = @{
            Margins = @{
                MarginLeft   = $MarginLeft
                MarginRight  = $MarginRight
                MarginTop    = $MarginTop
                MarginBottom = $MarginBottom
            }
            #PageSize = $PageSize
        }
    }
}

Register-ArgumentCompleter -CommandName New-PDFOptions -ParameterName PageSize -ScriptBlock $Script:PDFPageSize
function New-PDFPage {
    [CmdletBinding()]
    param(
        [ScriptBlock] $PageContent,
        [nullable[float]] $MarginLeft,
        [nullable[float]] $MarginRight,
        [nullable[float]] $MarginTop,
        [nullable[float]] $MarginBottom,
        [ValidateScript( { & $Script:PDFPageSizeValidation } )][string] $PageSize,
        [switch] $Rotate
    )
    if ($null -ne $Script:PDFStart -and $Script:PDFStart['Start']) {
        $Page = [PSCustomObject] @{
            Type     = 'Page'
            Settings = @{
                Margins     = @{
                    MarginLeft   = $MarginLeft
                    MarginRight  = $MarginRight
                    MarginTop    = $MarginTop
                    MarginBottom = $MarginBottom
                }
                PageSize    = $PageSize
                Rotate      = $Rotate.IsPresent
                PageContent = if ($PageContent) { & $PageContent } else { $null }
            }
        }
        $Page
    } else {
        # New-InternalPDFPage -PageSize $PageSize -Rotate:$Rotate.IsPresent
    }
}

Register-ArgumentCompleter -CommandName New-PDFPage -ParameterName PageSize -ScriptBlock $Script:PDFPageSize
function New-PDFTable {
    [CmdletBinding()]
    param(
        [Array] $DataTable
    )
    if ($null -ne $Script:PDFStart -and $Script:PDFStart['Start']) {
        $Settings = [PSCustomObject] @{
            Type     = 'Table'
            Settings = @{
                DataTable = $DataTable
            }
        }
        $Settings
    } else {
        New-InteralPDFTable -DataTable $DataTable
    }
}
function New-PDFText {
    [CmdletBinding()]
    param(
        [string[]] $Text,
        [ValidateScript( { & $Script:PDFFontValidationList } )][string[]] $Font,
        [ValidateScript( { & $Script:PDFColorValidation } )][string[]] $FontColor,
        [nullable[bool][]] $FontBold
    )
    $Splat = @{ }
    if ($Text) {
        $Splat['Text'] = $Text
    }
    if ($Font) {
        $Splat['Font'] = $Font
    }
    if ($FontColor) {
        $Splat['FontColor'] = $FontColor
    }
    if ($FontBold) {
        $Splat['FontBold'] = $FontBold
    }

    if ($null -ne $Script:PDFStart -and $Script:PDFStart['Start']) {
        $Settings = [PSCustomObject] @{
            Type     = 'Text'
            Settings = $Splat
        }
        $Settings
    } else {
        New-InternalPDFText @Splat
    }
}

Register-ArgumentCompleter -CommandName New-PDFText -ParameterName Font -ScriptBlock $Script:PDFFontList
Register-ArgumentCompleter -CommandName New-PDFText -ParameterName FontColor -ScriptBlock $Script:PDFColor
function Register-PDFFont {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FontName,
        [Parameter(Mandatory)][string] $FontPath,
        [ValidateScript( { & $Script:PDFFontEncodingValidation } )][string] $Encoding,
        [iText.Kernel.Font.PdfFontFactory+EmbeddingStrategy] $EmbeddingStrategy = [iText.Kernel.Font.PdfFontFactory+EmbeddingStrategy]::PREFER_EMBEDDED,
        [switch] $Cached,
        [switch] $Default
    )
    if (Test-Path -LiteralPath $FontPath) {
        try {
            if ($FontPath -and $Encoding) {
                $Script:Fonts[$FontName] = [iText.Kernel.Font.PdfFontFactory]::CreateFont($FontPath, [iText.IO.Font.PdfEncodings]::$Encoding, $EmbeddingStrategy, $Cached.IsPresent)
            } elseif ($FontPath) {
                $Script:Fonts[$FontName] = [iText.Kernel.Font.PdfFontFactory]::CreateFont($FontPath, $EmbeddingStrategy)
            }
        } catch {
            if ($PSBoundParameters.ErrorAction -eq 'Stop') {
                throw
            } else {
                Write-Warning "Register-PDFFont - Font registration failed. Error: $($_.Exception.Message)"
                return
            }
        }
        if (($Default -or $Script:Fonts.Count -eq 0) -and $Script:Fonts[$FontName]) {
            $Script:DefaultFont = $Script:Fonts[$FontName]
        }
    } else {
        if ($PSBoundParameters.ErrorAction -eq 'Stop') {
            throw "Font path '$FontPath' does not exist."
        } else {
            Write-Warning "Register-PDFFont - Font path does not exist. Path: $FontPath"
        }
    }
}

$Script:Fonts = [ordered] @{}
# Validation for Fonts Encoding
$Script:PDFFontEncoding = {
    ([iText.IO.Font.PdfEncodings] | Get-Member -Static -MemberType Property).Name
}
$Script:PDFFontEncodingValidation = {
    $Array = @(
        (& $Script:PDFFontEncoding)
        ''
    )
    $_ -in $Array
}
Register-ArgumentCompleter -CommandName Register-PDFFont -ParameterName Encoding -ScriptBlock $Script:PDFFontEncoding




# Export functions and aliases as required
Export-ModuleMember -Function @('Close-PDF', 'Convert-HTMLToPDF', 'Convert-PDFToText', 'Get-PDF', 'Get-PDFConstantAction', 'Get-PDFConstantColor', 'Get-PDFConstantFont', 'Get-PDFConstantPageSize', 'Get-PDFConstantVersion', 'Get-PDFDetails', 'Get-PDFFormField', 'Merge-PDF', 'New-PDF', 'New-PDFArea', 'New-PDFDocument', 'New-PDFImage', 'New-PDFInfo', 'New-PDFList', 'New-PDFListItem', 'New-PDFOptions', 'New-PDFPage', 'New-PDFTable', 'New-PDFText', 'Register-PDFFont', 'Set-PDFForm', 'Split-PDF') -Alias @()
# SIG # Begin signature block
# MIInPgYJKoZIhvcNAQcCoIInLzCCJysCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDcVrje5VkrLjVt
# Zl/0nba3ZaBISEafNtqdqbYDSV2beKCCITcwggO3MIICn6ADAgECAhAM5+DlF9hG
# /o/lYPwb8DA5MA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBa
# Fw0zMTExMTAwMDAwMDBaMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAK0OFc7kQ4BcsYfzt2D5cRKlrtwmlIiq9M71IDkoWGAM+IDaqRWVMmE8
# tbEohIqK3J8KDIMXeo+QrIrneVNcMYQq9g+YMjZ2zN7dPKii72r7IfJSYd+fINcf
# 4rHZ/hhk0hJbX/lYGDW8R82hNvlrf9SwOD7BG8OMM9nYLxj+KA+zp4PWw25EwGE1
# lhb+WZyLdm3X8aJLDSv/C3LanmDQjpA1xnhVhyChz+VtCshJfDGYM2wi6YfQMlqi
# uhOCEe05F52ZOnKh5vqk2dUXMXWuhX0irj8BRob2KHnIsdrkVxfEfhwOsLSSplaz
# vbKX7aqn8LfFqD+VFtD/oZbrCF8Yd08CAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFEXroq/0ksuCMS1Ri6enIZ3zbcgP
# MB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUA
# A4IBAQCiDrzf4u3w43JzemSUv/dyZtgy5EJ1Yq6H6/LV2d5Ws5/MzhQouQ2XYFwS
# TFjk0z2DSUVYlzVpGqhH6lbGeasS2GeBhN9/CTyU5rgmLCC9PbMoifdf/yLil4Qf
# 6WXvh+DfwWdJs13rsgkq6ybteL59PyvztyY1bV+JAbZJW58BBZurPSXBzLZ/wvFv
# hsb6ZGjrgS2U60K3+owe3WLxvlBnt2y98/Efaww2BxZ/N3ypW2168RJGYIPXJwS+
# S86XvsNnKmgR34DnDDNmvxMNFG7zfx9jEB76jRslbWyPpbdhAbHSoyahEHGdreLD
# +cOZUbcrBwjOLuZQsqf6CkUvovDyMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1
# b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtE
# aWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgx
# MDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLX
# cep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSR
# I5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXi
# TWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5
# Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8
# vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYD
# VR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4
# oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCow
# KAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZI
# AYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaA
# FEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPz
# ItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRu
# pY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKN
# JK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmif
# z0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN
# 3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKy
# ZqHnGKSaZFHvMIIFPTCCBCWgAwIBAgIQBNXcH0jqydhSALrNmpsqpzANBgkqhkiG
# 9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDYyNjAwMDAwMFoXDTIz
# MDcwNzEyMDAwMFowejELMAkGA1UEBhMCUEwxEjAQBgNVBAgMCcWabMSFc2tpZTER
# MA8GA1UEBxMIS2F0b3dpY2UxITAfBgNVBAoMGFByemVteXPFgmF3IEvFgnlzIEVW
# T1RFQzEhMB8GA1UEAwwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7KB3iyBrhkLUbbFe9qxhKKPBYqDBqln
# r3AtpZplkiVjpi9dMZCchSeT5ODsShPuZCIxJp5I86uf8ibo3vi2S9F9AlfFjVye
# 3dTz/9TmCuGH8JQt13ozf9niHecwKrstDVhVprgxi5v0XxY51c7zgMA2g1Ub+3ti
# i0vi/OpmKXdL2keNqJ2neQ5cYly/GsI8CREUEq9SZijbdA8VrRF3SoDdsWGf3tZZ
# zO6nWn3TLYKQ5/bw5U445u/V80QSoykszHRivTj+H4s8ABiforhi0i76beA6Ea41
# zcH4zJuAp48B4UhjgRDNuq8IzLWK4dlvqrqCBHKqsnrF6BmBrv+BXQIDAQABo4IB
# xTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYE
# FBixNSfoHFAgJk4JkDQLFLRNlJRmMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3
# BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25p
# bmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAmr1sz4ls
# LARi4wG1eg0B8fVJFowtect7SnJUrp6XRnUG0/GI1wXiLIeow1UPiI6uDMsRXPHU
# F/+xjJw8SfIbwava2eXu7UoZKNh6dfgshcJmo0QNAJ5PIyy02/3fXjbUREHINrTC
# vPVbPmV6kx4Kpd7KJrCo7ED18H/XTqWJHXa8va3MYLrbJetXpaEPpb6zk+l8Rj9y
# G4jBVRhenUBUUj3CLaWDSBpOA/+sx8/XB9W9opYfYGb+1TmbCkhUg7TB3gD6o6ES
# Jre+fcnZnPVAPESmstwsT17caZ0bn7zETKlNHbc1q+Em9kyBjaQRcEQoQQNpezQu
# g9ufqExx6lHYDjCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZI
# hvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNz
# dXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVow
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjww
# IjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J5
# 8soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMH
# hOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6
# Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQ
# ecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4b
# A3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9
# WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCU
# tNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvo
# ZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/J
# vNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCP
# orF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMB
# Af8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXr
# oq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRt
# MGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEF
# BQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgw
# BgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cH
# vZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8
# UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTn
# f+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxU
# jG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8j
# LfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5lDCCBq4w
# ggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQELBQAwYjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MB4X
# DTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UEBhMCVVMxFzAV
# BgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVk
# IEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTepl1Gh1tKD0Z5M
# om2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE
# 2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r07G1decfBmWN
# lCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFo
# bjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfAcsW6Th+xtVhN
# ef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3Vu
# JyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJSlRErWHRAKKtz
# Q87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4O
# uGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y99xh3pP+OcD5
# sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm
# 4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXTdrnSDmuZDNIz
# tM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6
# FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFdZEzfLmc/57qY
# rhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYB
# BQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# QQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZ
# MBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAgEAfVmO
# wJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoNqilp/GnBzx0H
# 6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/
# R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJodskr2dfNBwCnzv
# qLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6skHibBt94q6/ae
# sXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82HhyS7T6NJuXdm
# kfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3
# EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8zOYdBeHo46Zzh
# 3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIXmVnKcPA3v5gA
# 3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8
# BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsf
# gPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbAMIIEqKADAgECAhAMTWly
# S5T6PCpKPSkHgD1aMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYD
# VQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBH
# NCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIwOTIxMDAwMDAw
# WhcNMzMxMTIxMjM1OTU5WjBGMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGlnaUNl
# cnQxJDAiBgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAM/spSY6xqnya7uNwQ2a26HoFIV0Mxom
# rNAcVR4eNm28klUMYfSdCXc9FZYIL2tkpP0GgxbXkZI4HDEClvtysZc6Va8z7GGK
# 6aYo25BjXL2JU+A6LYyHQq4mpOS7eHi5ehbhVsbAumRTuyoW51BIu4hpDIjG8b7g
# L307scpTjUCDHufLckkoHkyAHoVW54Xt8mG8qjoHffarbuVm3eJc9S/tjdRNlYRo
# 44DLannR0hCRRinrPibytIzNTLlmyLuqUDgN5YyUXRlav/V7QG5vFqianJVHhoV5
# PgxeZowaCiS+nKrSnLb3T254xCg/oxwPUAY3ugjZNaa1Htp4WB056PhMkRCWfk3h
# 3cKtpX74LRsf7CtGGKMZ9jn39cFPcS6JAxGiS7uYv/pP5Hs27wZE5FX/NurlfDHn
# 88JSxOYWe1p+pSVz28BqmSEtY+VZ9U0vkB8nt9KrFOU4ZodRCGv7U0M50GT6Vs/g
# 9ArmFG1keLuY/ZTDcyHzL8IuINeBrNPxB9ThvdldS24xlCmL5kGkZZTAWOXlLimQ
# prdhZPrZIGwYUWC6poEPCSVT8b876asHDmoHOWIZydaFfxPZjXnPYsXs4Xu5zGcT
# B5rBeO3GiMiwbjJ5xwtZg43G7vUsfHuOy2SJ8bHEuOdTXl9V0n0ZKVkDTvpd6kVz
# HIR+187i1Dp3AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/
# BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEE
# AjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8w
# HQYDVR0OBBYEFGKK3tBh/I8xFO2XC809KpQU31KcMFoGA1UdHwRTMFEwT6BNoEuG
# SWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQw
# OTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQG
# CCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKG
# TGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJT
# QTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AFWqKhrzRvN4Vzcw/HXjT9aFI/H8+ZU5myXm93KKmMN31GT8Ffs2wklRLHiIY1UJ
# RjkA/GnUypsp+6M/wMkAmxMdsJiJ3HjyzXyFzVOdr2LiYWajFCpFh0qYQitQ/Bu1
# nggwCfrkLdcJiXn5CeaIzn0buGqim8FTYAnoo7id160fHLjsmEHw9g6A++T/350Q
# p+sAul9Kjxo6UrTqvwlJFTU2WZoPVNKyG39+XgmtdlSKdG3K0gVnK3br/5iyJpU4
# GYhEFOUKWaJr5yI+RCHSPxzAm+18SLLYkgyRTzxmlK9dAlPrnuKe5NMfhgFknADC
# 6Vp0dQ094XmIvxwBl8kZI4DXNlpflhaxYwzGRkA7zl011Fk+Q5oYrsPJy8P7mxNf
# arXH4PMFw1nfJ2Ir3kHJU7n/NBBn9iYymHv+XEKUgZSCnawKi8ZLFUrTmJBFYDOA
# 4CPe+AOk9kVH5c64A0JH6EE2cXet/aLol3ROLtoeHYxayB6a1cLwxiKoT5u92Bya
# UcQvmvZfpyeXupYuhVfAYOd4Vn9q78KVmksRAsiCnMkaBXy6cbVOepls9Oie1FqY
# yJ+/jbsYXEP10Cro4mLueATbvdH7WwqocH7wl4R44wgDXUcsY6glOJcB0j862uXl
# 9uab3H4szP8XTE0AotjWAQ64i+7m4HJViSwnGWH2dwGMMYIFXTCCBVkCAQEwgYYw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIENvZGUgU2lnbmluZyBDQQIQBNXcH0jqydhSALrNmpsqpzANBglghkgBZQME
# AgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCBWUsNVsIHNVPcZJ28W69cIjKaaqfWLNnKqPwthDQC3PDANBgkq
# hkiG9w0BAQEFAASCAQB3wGKGCapGnHl5+ud2eWvS2nQThlqIf3jOyaunwNb4JBcv
# YgXKEDeEbiiwQc/QQOBEvQzhvYgjsHfAW1Xc5MO/39xNJOfZZtrM+qZPQrRKYpPg
# P9nsK+RwETffQavjL4JDHRPQWjVtsdhhAniiF4Ixxu8cfhNgFhwy6Xbr1D3X3Syb
# 1bN00gCZVEvtL9M1sLQF9MLagbWMQZMr60OWUgj+z1xc9oXzzUNHUtWX+QzxlOu8
# bGKEbWKxWfAYzrqm5yM0XsIsxIxQzXNrIeukqILg3KsSd6k+KdlJlAh2Z7+VIYlF
# rEzkrlNcPSK4xrecoJO+aEUiJLeabd6a+rv7TJI/oYIDIDCCAxwGCSqGSIb3DQEJ
# BjGCAw0wggMJAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hB
# MjU2IFRpbWVTdGFtcGluZyBDQQIQDE1pckuU+jwqSj0pB4A9WjANBglghkgBZQME
# AgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTIyMTAwMjE3MjQyOFowLwYJKoZIhvcNAQkEMSIEIEiFzK3Wy58FVTTKCNNCdQgy
# g8cSSL8kfl7qBMxjBAhjMA0GCSqGSIb3DQEBAQUABIICAKtGVOkQfzfR4As3GERK
# xErsHplKsIUyrThD5hPbUV7FjBtGx0UYEhjsgjJdxQWKm0vOieKYeDhz0WdtT2AN
# 5mVSI6jpfovGGpMPLX8EQnCzvUcDOJBPNEh/ZQhZ8weM091I4k2jaZa3vk9Tbn+e
# uk5vvJ0EJwbzVm+Db1O+GPbcSGvbffLRsj/ueXCqmD8jVBacW/xUdwIsxb2GaLDU
# r0D2ShSKrhboRfGVV3IIY80DSD7LibkSjoRdTy6wiqhd+JndlaDWMtXxytVv+Niw
# s43skfvqhzQtuknpshgeGOm1hCxKyNB60JquAKCTrS5WHyq3QU+nwOrgOLd6TgsQ
# yw8rR3GzouiSe3Aktn+nRTkjmGPog9uBTgUgRXEIGwJ/S+Sg5Yas8oMK+7lg8Xdn
# QRpR5iPLLLthn7obbxtQjl/gzsyiry5GfLN+8gIiwd0CqL9PV7eiA8XmFsbNI0nA
# nYswvI7oH67PLO6ybe/X0g9kjlAn2/qdojdZ4rV4MJHJdX9xPvUlYn1CXRZXYnia
# +I4QoSVkQpJt+CtmrqMcrc+jaFXgqUE0AikHsumYV3ye0RZhToxG7M5KOqKPziFx
# Ru/PB1q7eR9VTAIRQDOfUWkiJ5sIwagGtWqyk2N2CZWgVNBN3WAfJY4yGIoiULK3
# /sSUWZbLZnnhr8C++ZNOLMB3
# SIG # End signature block
