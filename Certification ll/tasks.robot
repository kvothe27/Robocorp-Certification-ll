*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshoot of the ordered robot.
...                 Embeds the screenshoot of the robot to the PDF receipt.
...                 Creates Zip archive of the receipts and the images.

Library             RPA.Robocorp.Vault
Library             RPA.HTTP
Library             RPA.Browser.Selenium
Library             Dialogs
Library             RPA.FileSystem
Library             RPA.Email.ImapSmtp
Library             RPA.Cloud.Azure
Library             RPA.Tables
Library             RPA.Dialogs
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.FTP
Library             RPA.Archive


*** Variables ***
${download_path}=       ${CURDIR}${/}downloads
${order_csv}=           ${download_path}${/}orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Delete previus orders
    ${report}=    Download orders
    open the robot order website
    IF    ${report} == 1
        ${orders}=    Get orders
        FOR    ${order}    IN    @{orders}
            Wait Until Keyword Succeeds    6x    5 sec    Fill the form    ${order}
            ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
            Go to order another robot
        END
    ELSE
        Log    Report not found
    END
    Create a ZIP file of the receipts


*** Keywords ***
open the robot order website
    ${secret}=    Get Secret    credentials
    RPA.Browser.Selenium.Open Chrome Browser    ${secret}[url]
    RPA.Browser.Selenium.Click Element    //button[text()="OK"]

Delete previus orders
    ${files}=    List files in directory    ${download_path}
    FOR    ${file}    IN    @{FILES}
        Remove file    ${file}
    END

Download orders
    ${time}=    Set Variable    ${60}
    ${time_start}=    Set Variable    ${1}
    #${oders_url}=    Set Variable    https://robotsparebinindustries.com/orders.csv
    Add text input    url    label=Add csv URL

    ${result}=    Run dialog
    ${oders_url}=    Set Variable    ${result.url}
    Set Download Directory    ${download_path}
    Open Chrome Browser    ${oders_url}

    ${download_path}=    Set Variable    ${order_csv}

    ${file_exist}=    Does File Exist    ${download_path}

    WHILE    ${file_exist} != 1
        Sleep    1s
        ${file_exist}=    Does File Exist    ${download_path}
        IF    ${time_start} > ${time}
            BREAK
        ELSE
            ${time_start}=    Set Variable    ${time_start + 1}
        END
    END
    RETURN    ${file_exist}

Get orders
    ${table}=    Read table from CSV    ${order_csv}
    Log    Found columns: ${table.columns}
    RETURN    ${table}

Fill the form
    [Arguments]    ${order}
    ${order_numer}=    Set Variable    ${order}[Order number]
    ${order_head}=    Set Variable    ${order}[Head]
    ${order_body}=    Set Variable    ${order}[Body]
    ${order_legs}=    Set Variable    ${order}[Legs]
    ${order_address}=    Set Variable    ${order}[Address]

    Click Element    xpath://select
    Click Element    xpath://select/option[@value=${order_head}]

    Click Element    xpath://input[@value=${order_body}]
    Input Text    //label[text()="3. Legs:"]/parent::div/input    ${order_legs}
    Input Text    //input[@id="address"]    ${order_address}
    Click Element    //button[@id="preview"]
    Click Element    //button[@id="order"]
    Click Element    //div[@id="receipt"]

Store the receipt as a PDF file
    [Arguments]    ${oder_number}
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_${oder_number}.pdf

    Wait Until Element Is Visible    //div[@id="receipt"]
    ${receipt_html}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_path}

    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${oder_number}
    ${screenshoot_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}preview_${oder_number}.png
    Screenshot    //div[@id="robot-preview-image"]    ${screenshoot_path}

    RETURN    ${screenshoot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf_path}    ${screenshoot_path}
    Open PDF    ${pdf_path}
    ${files}=    Create List
    ...    ${pdf_path}
    ...    ${screenshoot_path}
    Add Files To Pdf    ${files}    ${pdf_path}
    Remove File    ${screenshoot_path}
    Close all pdfs

Go to order another robot
    Click Element    //button[@id="order-another"]
    Click Element    //button[text()="OK"]

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}completed.zip
