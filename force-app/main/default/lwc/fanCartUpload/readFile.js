/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

// wrapper around FileReader to work nicely in Promise chain
function readFile(file) {
    return new Promise(function(resolve, reject){
        var reader = new FileReader();
        const extension = file.name.split('.').pop().toLowerCase();
        reader.onload = function() {            
            resolve({
                content: reader.result,
                extension: extension
            });
        }
        reader.onerror = function() {
            reject(reader.error);
        }
        reader.onabort = function() {
            reject(new Error('Upload aborted.'));
        }
        if(extension === 'csv')
            reader.readAsText(file);
        else
            reader.readAsBinaryString(file);
    });
}

export { readFile };