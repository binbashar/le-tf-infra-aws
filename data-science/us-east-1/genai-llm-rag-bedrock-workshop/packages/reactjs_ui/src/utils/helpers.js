/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

const formatDates = (aDate) => {
    const newDate = new Date(aDate).toLocaleString()
    return newDate.slice(0, 17)
  }
  
  const formatBool = (val) => {
    return val ? "Y" : "N"
  }
  
  const getOportunities = (val) => {
    return val.oportunities?.items ? val.oportunities.items.length : 0
  }
  
  export { formatDates, formatBool, getOportunities}