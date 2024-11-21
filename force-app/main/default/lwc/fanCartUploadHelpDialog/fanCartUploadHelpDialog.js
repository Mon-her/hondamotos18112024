/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api } from 'lwc';

import { closeLabel } from 'c/fanLabels';

export default class FanCartUploadHelpDialog extends LightningElement {

    @api isOpen = false;

    @api contentId;
    @api contentType;

    get closeLabel() {
        return closeLabel();
    };

    handleCloseModal(event) {
        this.dispatchEvent(new CustomEvent('closehelpdialog'));
    }

}