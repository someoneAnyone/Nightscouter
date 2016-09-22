//
//  LocalizedStrings.swift
//  Nightscouter
//
//  Created by Peter Ina on 1/15/16.
//  Copyright © 2016 Nothingonline. All rights reserved.
//

import Foundation

public enum LocalizedString: String {
    case newSiteFormLabel,
    tableViewCellRemove,
    tableViewCellLoading,
    lastUpdatedDateLabel,
    lastReadingLabelShort,
    batteryLabelShort,
    rawLabelShort,
    generalEditLabel,
    generalCancelLabel,
    generalRetryLabel,
    generalYesLabel,
    generalNoLabel,
    uiAlertBadSiteMessage,
    uiAlertBadSiteTitle,
    uiAlertScreenOverrideTitle,
    uiAlertScreenOverrideMessage,
    sgvLowString,
    sgvWithEmojiString,
    directionRateOutOfRange,
    directionNotComputable,
    directionNone,
    directionDoubleUp,
    directionSingleUp,
    directionFortyFiveUp,
    directionFlat,
    directionFortyFiveDown,
    directionSingleDown,
    directionDoubleDown,
    viewTitleSettings,
    settingsPreventLocking,
    genericURLLabel,
    generalNextLabel,
    settingsDefaultSite,
    settingsDefaultSiteSubTitle,
    settingsEditSite,
    settingsEditSiteSubTitle,
    settingsGoToWeb,
    emptyTableViewCellTitle,
    nightscoutTitleString,
    lastReadingLabel,
    batteryLabel,
    rawLabel,
    updateDateFromPhoneString,
    sitePlural,
    siteSingle,
    selectASite,
    selected,
    snoozeLabel,
    snoozedForLabel,
    snoozeMessage,
    minutes,
    hour,
    hours,
    min
}

extension LocalizedString {
    public var localized: String {
        return self.rawValue.localized
    }
}
