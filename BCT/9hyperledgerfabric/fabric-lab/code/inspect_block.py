#!/usr/bin/env python3
"""Pretty-print the transactions of a decoded Fabric block (output of
`configtxlator proto_decode --type common.Block`)."""
import base64
import json
import sys

VALIDATION = {
    0: "VALID", 1: "NIL_ENVELOPE", 2: "BAD_PAYLOAD", 3: "BAD_COMMON_HEADER",
    4: "BAD_CREATOR_SIGNATURE", 5: "INVALID_ENDORSER_TRANSACTION",
    6: "INVALID_CONFIG_TRANSACTION", 7: "UNSUPPORTED_TX_PAYLOAD",
    8: "BAD_PROPOSAL_TXID", 9: "DUPLICATE_TXID", 10: "ENDORSEMENT_POLICY_FAILURE",
    11: "MVCC_READ_CONFLICT", 12: "PHANTOM_READ_CONFLICT", 13: "UNKNOWN_TX_TYPE",
    14: "TARGET_CHAIN_NOT_FOUND", 15: "MARSHAL_TX_ERROR", 16: "NIL_TXACTION",
    17: "EXPIRED_CHAINCODE", 18: "CHAINCODE_VERSION_CONFLICT", 19: "BAD_HEADER_EXTENSION",
    20: "BAD_CHANNEL_HEADER", 21: "BAD_RESPONSE_PAYLOAD", 22: "BAD_RWSET",
    23: "ILLEGAL_WRITESET", 24: "INVALID_WRITESET", 254: "NOT_VALIDATED", 255: "INVALID_OTHER_REASON",
}


def b64text(s):
    try:
        return base64.b64decode(s).decode("utf-8", "replace")
    except Exception:
        return str(s)


def flags_of(block):
    try:
        raw = block["metadata"]["metadata"][2]
    except (KeyError, IndexError, TypeError):
        return []
    if isinstance(raw, str):
        try:
            return list(base64.b64decode(raw))
        except Exception:
            return []
    if isinstance(raw, list):
        return [int(x) for x in raw]
    return []


def main(path):
    with open(path) as f:
        block = json.load(f)
    hdr = block.get("header", {})
    envs = block.get("data", {}).get("data", [])
    flags = flags_of(block)
    print("-" * 70)
    print(f"BLOCK #{hdr.get('number', '?')}   transactions: {len(envs)}")
    print(f"  data_hash:     {hdr.get('data_hash', '')[:40]}...")
    print(f"  previous_hash: {hdr.get('previous_hash', '')[:40]}...   (hash chain => tamper evident)")
    for i, env in enumerate(envs):
        payload = env.get("payload", {})
        header = payload.get("header", {})
        ch = header.get("channel_header", {})
        code = flags[i] if i < len(flags) else None
        label = VALIDATION.get(code, str(code)) if code is not None else "unknown"
        print(f"  TX[{i}] id={ch.get('tx_id', '')[:24]}...  type={ch.get('type')}  "
              f"time={ch.get('timestamp', '')}")
        print(f"        validation result : {label}")
        creator = header.get("signature_header", {}).get("creator", {})
        print(f"        submitted by MSP  : {creator.get('mspid', '?')}")
        actions = payload.get("data", {}).get("actions")
        if not actions:
            print("        (config / non-endorser transaction)")
            continue
        for act in actions:
            ap = act.get("payload", {})
            spec = (ap.get("chaincode_proposal_payload", {}).get("input", {})
                    .get("chaincode_spec", {}))
            args = [b64text(a) for a in spec.get("input", {}).get("args", [])]
            print(f"        chaincode         : {spec.get('chaincode_id', {}).get('name', '?')}")
            print(f"        function + args   : {args}")
            cea = ap.get("action", {})
            endorsers = [e.get("endorser", {}).get("mspid", "?") for e in cea.get("endorsements", [])]
            print(f"        endorsed by       : {endorsers}")
            ext = cea.get("proposal_response_payload", {}).get("extension", {})
            print(f"        chaincode status  : {ext.get('response', {}).get('status', '?')}")
            for ns in ext.get("results", {}).get("ns_rwset", []) or []:
                if ns.get("namespace", "").startswith("_"):
                    continue
                rw = ns.get("rwset", {})
                for r in rw.get("reads", []) or []:
                    ver = r.get("version") or {}
                    print(f"        READ  {r.get('key')}  (version block={ver.get('block_num')} tx={ver.get('tx_num')})")
                for w in rw.get("writes", []) or []:
                    if w.get("is_delete"):
                        print(f"        WRITE {w.get('key')} = <DELETE>")
                    else:
                        print(f"        WRITE {w.get('key')} = {b64text(w.get('value', ''))}")
    print("-" * 70)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: inspect_block.py <decoded_block.json>")
    main(sys.argv[1])
