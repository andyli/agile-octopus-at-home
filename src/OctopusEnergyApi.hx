import js.node.url.URLSearchParams;
import js.lib.Promise;
import haxe.io.Bytes;
import haxe.io.Path.join;
import haxe.crypto.Base64;
import js.npm.NodeFetch.fetch;
using DateTools;

class OctopusEnergyApi {
    final baseUrl:String = "https://api.octopus.energy";
    final apiKey:String;

    public function new(apiKey:String):Void {
        this.apiKey = apiKey;
    }

    public function getProducts():Promise<Dynamic> {
        final url = join([baseUrl, "/v1/products/"]);
        final auth = "Basic " + Base64.encode(Bytes.ofString(this.apiKey + ":"));
        return fetch(url, {
            headers: {
                Authorization: auth,
            }
        })
            .then(r -> {
                if (!r.ok) {
                    throw "Error: " + r.status + " " + r.statusText;
                }
                r.json();
            });
    }

    public function getElectricityStandardUnitRates(productCode:String, tariffCode:String, ?options:{
        final ?periodFrom:Date;
        final ?periodTo:Date;
        final ?pageSize:Int;
    }):Promise<{
        final count:Int;
        final next:Null<String>;
        final previous:Null<String>;
        final results:Array<{
            final value_exc_vat:Float;
            final value_inc_vat:Float;
            final valid_from:String;
            final valid_to:String;
            final payment_method:Null<String>;
        }>;
    }> {
        final url = join([baseUrl, '/v1/products/${productCode}/electricity-tariffs/${tariffCode}/standard-unit-rates/']);
        final auth = "Basic " + Base64.encode(Bytes.ofString(this.apiKey + ":"));
        final params = new URLSearchParams();
        if (options != null) {
            if (options.periodFrom != null) {
                params.append("period_from", options.periodFrom.format("%Y-%m-%dT%H:%M:%S"));
            }
            if (options.periodTo != null) {
                params.append("period_to", options.periodTo.format("%Y-%m-%dT%H:%M:%S"));
            }
            if (options.pageSize != null) {
                params.append("page_size", Std.string(options.pageSize));
            }
        }
        return fetch(url + "?" + params, {
            headers: {
                Authorization: auth,
            }
        })
            .then(r -> {
                if (!r.ok) {
                    throw "Error: " + r.status + " " + r.statusText;
                }
                r.json();
            });
    }
}