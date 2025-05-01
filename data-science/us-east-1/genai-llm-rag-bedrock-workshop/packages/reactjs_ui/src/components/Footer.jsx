/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import binbashLogo from "../assets/images/binbash_logo.png";

const Footer = () => {
    return (
        <footer className="custom-main-footer">
            <div className="company-logo">
                <span className="vertically-centered">
                    <img src={binbashLogo} alt="Binbash" />
                    <span>Binbash</span>
                </span>
            </div>
            <div className="copyright">
                © 2025, Binbash Corp
            </div>
        </footer>
    );
};

export default Footer;