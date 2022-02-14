*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library     RPA.Browser
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.Desktop
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.FileSystem
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault

*** Keywords ***
Vault URL
    ${secret}=  Get Secret  cert2url
    ${url}=  ${secret}[url]
    Log   ${url}

*** Keywords ***
Dialog
    Add heading     Input CSV URL
    Add text input      URL     label=URL
    ${result}=      Run dialog
    [Return]  ${result.URL}

*** Keywords ***
Open the robot order website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Get orders
    [Arguments]   ${url}
    Download    ${url}  overwrite=True
    ${orders}=  Read table from CSV    orders.csv  header=True
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Click Button    OK

*** Keywords ***
Fill the form
    [Arguments]  ${orders}
    Select From List By Index    id:head  ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]

*** Keywords ***
Preview the robot
    Click Button    Preview

*** Keywords ***
Submit the order
    Click Button    Order
    Page Should Contain     Receipt

*** Keywords ***
Order another robot
    Click Button   id:order-another 

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]      ${orders}
    ${receipt_data}=    Get Element Attribute   id:receipt  outerHTML
    Create Directory        ${OUTPUT_DIR}${/}Robot Receipt                
    Html To Pdf     ${receipt_data}     ${OUTPUT_DIR}${/}Robot Receipt${/} ${orders}[Order number].PDF
    [Return]    ${OUTPUT_DIR}${/}Robot Receipt${/} ${orders}[Order number].PDF

*** Keywords ***
Take a screenshot of the robot
    [Arguments]  ${orders}
    Screenshot  id= robot-preview-image      image${orders}[Order number].jpeg
    [Return]    image${orders}[Order number].jpeg

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${pdf}      ${screenshot}
    Open PDF        ${pdf}
    @{files}=   Create List     ${screenshot}
    Add Files To PDF        ${files}       ${pdf}      append=True      
    Close PDF       ${pdf}

*** Keywords ***
Create ZIP
    Archive Folder With Zip     ${OUTPUT_DIR}${/}Robot Receipt      pdfs.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    #Vault URL
    ${url}=  Dialog
    Open the robot order website    
    ${orders}=  Get orders  ${url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds  3x  1s  Preview the robot
        Wait Until Keyword Succeeds  10x  1s  Submit the order
        ${pdf}=     Store the receipt as a PDF file     ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Create ZIP
        Embed the robot screenshot to the receipt PDF file    ${pdf}       ${screenshot}    
        Order another robot
        
        
    END
