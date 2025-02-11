/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as React from "react";
import TopNavigation from "@cloudscape-design/components/top-navigation";
import { useNavigate } from "react-router-dom";
import { Mode, applyMode } from "@cloudscape-design/global-styles";
import 'highlight.js/styles/atom-one-dark.css';
import PaceLogo from "../assets/images/pace.svg?react";

const Menu = ({ signOut, groups, ...user }) => {
  const [isDarkMode, setIsDarkMode] = React.useState(true);

  let navigate = useNavigate();

  const menuFollow = (e) => {
    console.log("Menu Follow:", e);
    e.preventDefault();
    if (e.detail?.href) {
      navigate(e.detail.href);
    }
  };

  const handleSignout = (e) => {
    console.log("Logout:", e);
    console.log("User:", user);
    e.preventDefault();
    if (e.detail.id == "signout") signOut();
  };

  const updateMode = (e) => {
    console.log("Update Mode:", e.detail.id);

    const storedThemeMode = sessionStorage.getItem('themeMode');
    console.log("Stored theme mode:", storedThemeMode);

    // Check if the stored theme mode is a valid value for the Mode enum
    const isValidMode = Object.values(Mode).includes(storedThemeMode);
    console.log("Is valid mode:", isValidMode);

    if (isValidMode) {
      if (storedThemeMode === Mode.Dark && e.detail.id === "settings-mode-light") {
        // Update session storage
        sessionStorage.setItem('themeMode', Mode.Light);
        // Update State variable
        setIsDarkMode(false);
        // Apply new Mode
        applyMode(Mode.Light);
      } else if (storedThemeMode === Mode.Light && e.detail.id === "settings-mode-dark") {
        // Update session storage
        sessionStorage.setItem('themeMode', Mode.Dark);
        // Update State variable
        setIsDarkMode(true);
        // Apply new Mode
        applyMode(Mode.Dark);
      }
      console.log("Stored theme mode after update:", sessionStorage.getItem('themeMode'));
    }
  }

  return (
    <div id="h" style={{ position: 'sticky', top: 0, zIndex: 1002, borderBlockEnd: 'solid 1px #414d5c' }}>
    <TopNavigation
      identity={{
        onFollow: () => {
          navigate("/");
        },
        title: <div className="header-title"><PaceLogo className="small-icon"></PaceLogo>Generative AI Developer Workshop </div>,
      }}
      utilities={[
        {
          type: "menu-dropdown",
          text: `${user.signInDetails?.loginId}`,
          onItemClick: (e) => {
            handleSignout(e);
          },
          iconName: "user-profile",
          items: [
            {
              id: "signout",
              text: "Sign Out",
            },
          ],
        },
        {
          type: "menu-dropdown",
          iconName: "settings",
          title: "Visual Mode",
          ariaLabel: "Settings",
          badge: false,
          disableUtilityCollapse: false,
          items: [{
            id: "settings-mode-light",
            text: "Light"
          },
          {
            id: "settings-mode-dark",
            text: "Dark"
          }],
          onItemClick: (e) => {
            updateMode(e);
          },
        },
      ]}
      i18nStrings={{
        searchIconAriaLabel: "Search",
        searchDismissIconAriaLabel: "Close search",
        overflowMenuTriggerText: "More",
        overflowMenuTitleText: "All",
        overflowMenuBackIconAriaLabel: "Back",
        overflowMenuDismissIconAriaLabel: "Close menu",
      }}
    />
  </div>
  );
};

export default Menu;
