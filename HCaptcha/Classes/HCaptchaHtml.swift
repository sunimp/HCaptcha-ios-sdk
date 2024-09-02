//
//  HCaptchaHtml.swift
//
//  Created by Sun on 2022/7/22.
//

import Foundation

enum HCaptchaHtml {
    static var template = """
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no"/>

                <style>
                    * {
                        padding: 0;
                        margin: 0;
                    }
                    body {
                        display: table;
                        width: 100%;
                        height: 100%;
                        text-align: center;
                    }
                    #hcaptcha-container {
                        margin-top: 5px;
                        display: table-cell;
                        vertical-align: middle;
                    }
                    /* overwrite hCaptcha iframe overlay which adds a #FFF background with opacity 0.05 */
                    div > div:nth-child(2) {
                        opacity: 0 !important;
                    }
                </style>
                <script type="text/javascript">
                  JSON.parse('${debugInfo}' || "[]").forEach(function (value, i) { window[value] = true; });
                </script>
                <script type="text/javascript">
                  var script = document.createElement('script');
                  script.src = "${endpoint}";

                  script.onerror = function () {
                      // network issue
                      post({ error: 7 });
                  };

                  document.head.appendChild(script);
                </script>
                <script type="text/javascript">
                  var post = function(value) {
                    window.webkit.messageHandlers.hcaptcha.postMessage(value);
                  };

                  var getExecuteOpts = function() {
                    var opts;
                    var rqdata = "${rqdata}";
                    if (rqdata) {
                      opts = {'rqdata': rqdata};
                    }
                    return opts;
                  };

                  console.log = function(message) {
                    post({ log: message });
                  };

                  var execute = function() {
                    console.log("challenge executing");

                    try {
                      if ("${size}" === 'invisible') {
                        hcaptcha.execute(getExecuteOpts());
                      } else {
                        post({ action: "showHCaptcha" });
                      }

                      console.log("showing challenge");
                    } catch (e) {
                      console.log("failed to show challenge");
                      post({ error: 29 });
                    }
                  };

                  var reset = function() {
                    console.log("challenge resetting");
                    hcaptcha.reset();
                    post({ action: "didLoad" });
                  };

                  var onPass = function(token) {
                    console.log("challenge got token");
                    console.log(token);
                    post({ token: token });
                  };

                  var expiredCallback = function(action) {
                    return function() {
                      console.log("expired challenge");
                      post({ error: 15 });
                      post({ action: action });
                    };
                  };

                  var errorCallback = function(error) {
                    console.log("challenge error:", error || "probably rate limit exceeded");
                    post({ error: 31 });
                  };

                  var closeCallback = function() {
                    console.log("challenge closed by user");
                    post({ error: 30 });
                    post({ action: "onClose" });
                  };

                  var openCallback = function(e) {
                    console.log("challenge opened", e);
                    post({ action: "showHCaptcha" });
                    post({ action: "onOpen" });
                  };

                  var onloadCallback = function() {
                    try {
                      console.log("challenge onload starting");
                      hcaptcha.render("hcaptcha-container", {
                        "sitekey": "${apiKey}",
                        "size": "${size}",
                        "orientation": "${orientation}",
                        "theme": ${theme},
                        "callback": onPass,
                        "close-callback": closeCallback,
                        "expired-callback": expiredCallback("onExpired"),
                        "chalexpired-callback": expiredCallback("onChallengeExpired"),
                        "error-callback": errorCallback,
                        "open-callback": openCallback,
                      });

                      post({ action: "didLoad" });
                    } catch (e) {
                      console.log("challenge failed to render");
                      post({ error: 29 });
                    }
                  };

                  document.addEventListener('DOMContentLoaded', function () {
                    var container = document.getElementById("hcaptcha-container");
                    container.addEventListener("click", function () {
                      if (window.hcaptcha) {
                        // Allows dismissal of checkbox view
                        window.hcaptcha.close();
                      } else {
                        post({ error: 30 });
                      }
                    });
                  });
                </script>
              </head>
              <body>
                <div id="hcaptcha-container">
                </div>
              </body>
            </html>
        """
}
