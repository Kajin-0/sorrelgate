#!/usr/bin/env python3
"""Build real, selectable-text, synthetic PDFs for a first Sorrelgate Mac pilot.

Uses only Python standard library on developer/CI machines.
No Python dependency exists in the shipped application.
"""
import csv
from pathlib import Path
import sys

FIXTURES = {
    "01-Accepted-Offer-Sample.pdf": [
        [
            "SYNTHETIC TRAINING DOCUMENT - NOT A REAL CONTRACT",
            "Transaction: Example accepted offer (fabricated)",
            "Property: 123 Example Lane, Sampletown, CA",
            "Seller: Fictional Seller",
            "Buyer: Fictional Buyer",
            "Use only for testing Sorrelgate.",
        ],
        [
            "SYNTHETIC TRAINING DOCUMENT - PAGE 2",
            "Acceptance Date: 2026-11-20",
            "Purchase Price: $650,000.00",
            "Fabricated example values, not verified facts.",
        ],
        [
            "SYNTHETIC TRAINING DOCUMENT - PAGE 3",
            "Closing Date: 2026-12-21",
            "Review source pages before confirming anything.",
        ],
    ],
    "02-Conflicting-Facts-Sample.pdf": [
        [
            "SYNTHETIC TRAINING DOCUMENT - NOT A REAL CONTRACT",
            "Purchase Price: $675,000.00",
            "Deliberate conflict with the first example document.",
        ],
        [
            "SYNTHETIC TRAINING DOCUMENT - PAGE 2",
            "Closing Date: 2026-12-28",
            "Deliberate conflicting closing date for review.",
        ],
    ],
    "03-Unknown-Fields-Sample.pdf": [
        [
            "SYNTHETIC TRAINING DOCUMENT - NOT A REAL CONTRACT",
            "Acceptance Date: TBD",
            "Closing Date: TBD",
            "Purchase Price: TBD",
            "Sorrelgate should not invent unknown facts.",
        ],
        [
            "SYNTHETIC TRAINING DOCUMENT - PAGE 2",
            "No real signature, disclosure or legal document exists.",
            "A coordinator must check originals manually.",
        ],
    ],
}

def escaped(text: str) -> str:
    text.encode("ascii")
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

def generate_pdf(pages: list[list[str]]) -> bytes:
    # Objects 1/2/3: PDF catalog, page tree, standard Type1 font.
    objects: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    kids: list[str] = []
    for lines in pages:
        page_id = len(objects) + 1
        content_id = page_id + 1
        kids.append(f"{page_id} 0 R")
        commands = ["BT", "/F1 13 Tf", "48 744 Td"]
        for line in lines:
            commands.append(f"({escaped(line)}) Tj")
            commands.append("0 -32 Td")
        commands.append("ET")
        stream = ("\n".join(commands) + "\n").encode("ascii")
        objects.append((
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
            f"/Resources << /Font << /F1 3 0 R >> >> "
            f"/Contents {content_id} 0 R >>"
        ).encode("ascii"))
        objects.append(
            f"<< /Length {len(stream)} >>\nstream\n".encode("ascii")
            + stream + b"endstream"
        )
    objects[1] = (
        f"<< /Type /Pages /Kids [{' '.join(kids)}] /Count {len(pages)} >>"
    ).encode("ascii")
    output = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for number, obj in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{number} 0 obj\n".encode("ascii"))
        output.extend(obj)
        output.extend(b"\nendobj\n")
    startxref = len(output)
    output.extend(f"xref\n0 {len(objects)+1}\n".encode("ascii"))
    output.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n \n".encode("ascii"))
    output.extend((
        f"trailer\n<< /Size {len(objects)+1} /Root 1 0 R >>\n"
        f"startxref\n{startxref}\n%%EOF\n"
    ).encode("ascii"))
    return bytes(output)

def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: generate_beta_fixtures.py OUTPUT_DIRECTORY")
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    for filename, pages in FIXTURES.items():
        (output / filename).write_bytes(generate_pdf(pages))
    with (output / "04-Optional-Office-Checklist.csv").open(
        "w", encoding="utf-8", newline=""
    ) as handle:
        writer = csv.writer(handle)
        writer.writerow(["Task", "Requirement", "Notes"])
        writer.writerow(["Receive accepted offer", "Required", "Synthetic sample only"])
        writer.writerow(["Review signature pages", "Optional", "Human review required"])
        writer.writerow(["Prepare introduction", "Unspecified", "Not sent by Sorrelgate"])
    print("BETA_FIXTURES_GENERATED pdf_count=3 total_pages=7 csv_count=1")

if __name__ == "__main__":
    main()
