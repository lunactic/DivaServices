import * as url from 'url';
/**
 * Created by lunactic on 03.11.16.
 */

import * as path from "path";
import * as nconf from "nconf";

/**
 * class representing an internal data item
 * 
 * @export
 * @class DivaData
 */
export class DivaData {

    /**
     * the foldername of the image on the filesystem
     * 
     * @type {string}
     * @memberOf DivaData
     */
    public folder: string;
    /**
     * the name of the data item
     * 
     * @type {string}
     * @memberOf DivaData
     */
    public filename: string;
    

    /**
     * the name of the collection
     * @type {string}
     * @memberOf DivaData
     */
    public collection: string;

    /**
     * the file extension
     * 
     * @type {string}
     * @memberOf DivaData
     */
    public extension: string;
    /**
     * the full path to the data file
     * 
     * @type {string}
     * @memberOf DivaData
     */
    public path: string;
    /**
     * the md5 hash of the image
     * 
     * @type {string}
     * @memberOf DivaData
     */
    public md5: string;

    /**
     * the public url to retrieve this file
     */
    public url: string;

    constructor() {
        this.folder = "";
        this.filename = "";
        this.extension = "";
        this.path = "";
        this.md5 = "";
    }


    static CreateDataItem(collection: string, filename: string): DivaData {
        let item = new DivaData();
        item.collection = collection;
        item.filename = filename;
        item.extension = filename.split(".").pop();
        item.path = nconf.get("paths:filesPath") + path.sep + collection + path.sep + "original" + path.sep + filename;
        item.url = "http://" + nconf.get("server:rootUrl") + "/files/" + collection + "/original/" + filename;
        return item;
    }

}