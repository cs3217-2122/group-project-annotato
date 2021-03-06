import WebKit

// References: https://stackoverflow.com/questions/45998220/the-font-looks-like-smaller-in-wkwebview-than-in-uiwebview
extension WKWebView {
    /// Load HTML String same font like the UIWebview
    ///
    /// - Parameters:
    ///   - content: HTML content which we need to load in the webview.
    ///   - baseURL: Content base url. It is optional.
    func loadHTMLStringWithCorrectScale(content: String, baseURL: URL?) {
        let rawHtmlString =
            """
            <html lang="en">
                <head>
                    <meta name='viewport' content='width=device-width,
                          initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0,
                          user-scalable=no'>
                </head>

                <body>
                    \(content)
                </body>
            </html>
            """
        loadHTMLString(rawHtmlString, baseURL: baseURL)
    }

    func changeFont(fontFamilies: String) {
        let changeFontFamilyScript =
            """
            document.getElementsByTagName(\'body\')[0].style.fontFamily = \"\(fontFamilies)\";
            """
        evaluateJavaScript(changeFontFamilyScript)
    }
}
