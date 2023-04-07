*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set Environment    Imgs
    Set Environment    Pdfs
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Store the receipt as a PDF file    ${order}[Order number]
    END
    Converting to ZIP
    [Teardown]    Close Browser


*** Keywords ***
Set Environment
    [Arguments]    ${path-check}
    ${Dir-check}=    Does Directory Exist    ${path-check}
    IF    ${Dir-check}
        Empty Directory    ${path-check}
    ELSE
        Create Directory    ${path-check}
    END

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=${True}

Close the annoying modal
    Click Element If Visible    css:button.btn-dark

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    css:input[type="number"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Wait Until Keyword Succeeds    10 x    1 s    Check preview
    Wait Until Keyword Succeeds    10 x    1 s    Check receipt

Check preview
    Click Button    id:preview
    Sleep    200ms
    Wait Until Element Is Visible    id:robot-preview-image

Check receipt
    Click Button    id:order
    Sleep    200ms
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${id}
    ${pdf-path}=    Set Variable    Pdfs/Order_${id}.pdf
    ${img-path}=    Set Variable    Imgs/Order_${id}.png
    Screenshot    id:robot-preview-image    ${img-path}
    ${content}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${content}<br/><img src=${img-path}>    ${pdf-path}
    Click Button    id:order-another
    Close the annoying modal

Converting to ZIP
    Archive Folder With Zip    Pdfs    ${OUTPUT_DIR}${/}Pdfs.zip
