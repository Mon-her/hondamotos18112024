/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api } from 'lwc';

import { resultsLabel } from 'c/fanLabels';

export default class FanCartUploadProcessLog extends LightningElement {

    @api showProcessLog;
    @api richtext;

    get resultsLabel() {
        return resultsLabel();
    }
}