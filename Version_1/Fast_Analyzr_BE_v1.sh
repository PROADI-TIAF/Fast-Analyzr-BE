#!/usr/bin/env bash

# Set locale to ensure printf uses a decimal point for numbers
export LC_NUMERIC="C"
export LANG="C"

# Define the color codes
NC='\033[0m'             # No color
RED='\033[0;31m'         # Red

echo "Checking Bash version..."

# Get the Bash version currently in use
current_bash_version=$(echo "$BASH_VERSION" | cut -d'(' -f1)

# Define the minimum required version
min_bash_version="4.0"

echo "Current Bash version: $current_bash_version"
echo "Required minimum version: $min_bash_version"

# Compare versions numerically.
if printf "%s\n%s" "$min_bash_version" "$current_bash_version" | sort -V -c &>/dev/null; then
    echo "Your Bash version ($current_bash_version) is $min_bash_version or newer. You're good to go!"
else
    echo -e "${RED}ERROR: Your Bash version ($current_bash_version) is older than $min_bash_version.${NC}"
    echo -e "${RED}It's recommended to update Bash for better compatibility and features.${NC}"
    exit 1 # Exit with an error code
fi

# Function to display the ASCII art header
display_header() {
echo ""
echo -e "${NC}                                                         ~~~ Fast Analyzr BE ~~~${NC}"
echo -e "${NC}                                     A script for quick and easy analysis focused on base editors${NC}"
echo ""
echo -e "${NC}                           _    _                                                                                  _    _${NC}"
echo -e "${NC}                          (_\__/(,_                    ____________________________                               (_\__/(,_${NC}"
echo -e "${NC}                          | \  _////-._               |  __  __  __ ___    __  __  |                              | \  _////-._   ${NC}"
echo -e "${NC}           _    _         L_/__  => __/ \             | |__ |__||__  |    |__)|__  |               _    _         L_/__  => __/ \    ${NC}"
echo -e "${NC}          (_\__/(,_       |=====;__/___./             | |   |  | __| |    |__)|__  |              (_\__/(,_       |=====;__/___./   ${NC}"
echo -e "${NC}          | \  _////-._   '-'-'-''''''''              |____________________________|              | \  _////-._   '-'-'-''''''''   ${NC}"
echo -e "${NC}          J_/___'=> __/ \                                                                         J_/___'=> __/ \ ${NC}"
echo -e "${NC}          |=====;__/___./                                     [Version 1.0]                       |=====;__/___./ ${NC}"
echo -e "${NC}          '-'-'-''''''''                                                                          '-'-'-'''''''' ${NC}"                                                                                     
echo ""
}

# Function to display the ASCII art footer
display_footer() {
echo -e "${NC}                           _    _                                                     _    _${NC}"
echo -e "${NC}                          (_\__/(,_                                                  (_\__/(,_${NC}"
echo -e "${NC}                          | \  _////-._                                             | \  _////-._   ${NC}"
echo -e "${NC}           _    _         L_/__  => __/ \                            _    _         L_/__  => __/ \    ${NC}"
echo -e "${NC}          (_\__/(,_       |=====;__/___./                           (_\__/(,_       |=====;__/___./   ${NC}"
echo -e "${NC}          | \  _////-._   '-'-'-''''''''                            | \  _////-._   '-'-'-''''''''   ${NC}"
echo -e "${NC}          J_/___'=> __/ \                                           J_/___'=> __/ \ ${NC}"
echo -e "${NC}          |=====;__/___./                                           |=====;__/___./ ${NC}"
echo -e "${NC}          '-'-'-''''''''                                            '-'-'-'''''''' ${NC}"                                                   
echo ""
}

# Function to display the help message
display_help() {
    display_header
    echo ""
    echo -e "${NC}Description:${NC}"
    echo -e "${NC}  This script automates the CRISPResso2 analysis pipeline. It creates the txt${NC}"
    echo -e "${NC}  files in the current directory, runs CRISPResso2 on each file, and then${NC}"
    echo -e "${NC}  performs further analysis using R.${NC}"
    echo ""
    echo -e "${NC}Usage: $0 [OPTIONS]${NC}"
    echo -e "${NC}Options:${NC}"
    echo -e "${NC}  -h, --help                          Display this help message${NC}"
    echo -e "${NC}  -n, --no-batch                      Do not open the HTML file and create the Batch file${NC}"
    echo -e "${NC}  -s, --skip-batch-crispresso         Skip Batch file creation and CRISPResso2 execution${NC}"
    echo -e "${NC}  -c, --crispresso <key> [<value>]    Add a custom argument to CRISPRessoBatch execution.${NC}"
    echo -e "${NC}                                      Allowed keys:   min_frequency_alleles_around_cut_to_plot <0-100>,"
    echo -e "${NC}                                                      base_editor_output," 
    echo -e "${NC}                                                      conversion_nuc_from <A,T,C,G>,"
    echo -e "${NC}                                                      conversion_nuc_to <A,T,C,G>,"
    echo -e "${NC}                                                      n_processes <Number of processes. Can be set to 'max'>.${NC}" 
    echo ""
}

# Gets the current execution directory
current_dir=$(pwd)

# Variable to store the names of the .txt files found
txt_files_found=""

# Initializes control variables
open_html=true
run_crispresso=true

# Control flags to detect mutual exclusion
no_batch_invoked=false
skip_batch_invoked=false

# Array to store custom arguments
custom_opts=()

# Manual processing of command line arguments to support multiple -c
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -n|--no-batch)
            # mark that -n was used and bypass HTML creation
            no_batch_invoked=true
            open_html=false
            shift
            ;;
        -s|--skip-batch-crispresso)
            # mark that -s was used and bypass both batch and HTML creation
            skip_batch_invoked=true
            run_crispresso=false
            open_html=false
            shift
            ;;
        -c|--crispresso)
            shift
            if [ $# -lt 1 ]; then
                echo -e "${RED}Error: -c/--crispresso requires at least a key argument.${NC}"
                exit 1
            fi
            key="$1"
            shift
            value=""
            if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
                value="$1"
                shift
            fi

            case "$key" in
                min_frequency_alleles_around_cut_to_plot)
                    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 0 ] && [ "$value" -le 100 ]; then
                        custom_opts+=( "--$key" "$value" )
                    else
                        echo -e "${RED}Error: Invalid value for $key. Must be an integer between 0 and 100.${NC}"
                        exit 1   
                    fi   
                    ;;
                base_editor_output)
                    custom_opts+=( "--$key" )
                    ;;
                conversion_nuc_from)
                    if [[ "$value" =~ ^[ATCG]$ ]]; then
                        custom_opts+=( "--$key" "$value" )
                    else
                        echo -e "${RED}Error: Invalid value for $key. Must be one of A, T, C, or G.${NC}"
                        exit 1
                    fi
                    ;;
                conversion_nuc_to)
                    if [[ "$value" =~ ^[ATCG]$ ]]; then
                        custom_opts+=( "--$key" "$value" )
                    else
                        echo -e "${RED}Error: Invalid value for $key. Must be one of A, T, C, or G.${NC}"
                        exit 1
                    fi
                    ;;
                n_processes) # Added n_processes validation
                    if [[ "$value" =~ ^([0-9]{1,2}|100|max)$ ]]; then
                        custom_opts+=( "--$key" "$value" )
                    else
                        echo -e "${RED}Error: Invalid value for $key. Must be an integer more or equal to 1.${NC}"
                        exit 1
                    fi
                    ;;
                *)
                    echo -e "${RED}Error: Invalid CRISPResso option: $key. Allowed options are:"
                    echo -e "        min_frequency_alleles_around_cut_to_plot, base_editor_output,"
                    echo -e "        conversion_nuc_from, conversion_nuc_to, n_processes${NC}" # Updated help message
                    exit 1
                    ;;
            esac
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "${RED}Invalid option: $1${NC}"
            display_help
            exit 1
            ;;
    esac
done

# Mutual exclusion verification for -n and -s
if $no_batch_invoked && $skip_batch_invoked; then
    echo -e "${RED}Error: Options -n/--no-batch and -s/--skip-batch-crispresso are mutually exclusive.${NC}"
    exit 1
fi

# Initial search for .txt files
found_txt_files=()
for file in "$current_dir"/*.txt; do
    if [ -e "$file" ]; then
        found_txt_files+=("$file")
    fi
done

display_header
echo ""

if ! $open_html; then
    # Automatic mode (using -n or -s)
    # Expect .txt files to be already present to proceed.
    if [ ${#found_txt_files[@]} -eq 0 ]; then
        echo -e "${RED}No txt file found and HTML creation skipped. The process will not continue.${NC}"
        exit 1
    fi
else
    # Manual mode (without -n and -s)
    # If any .txt files already exist, abort to avoid conflicts.
    if [ ${#found_txt_files[@]} -gt 0 ]; then
        echo -e "${RED}Error: Found the following .txt files in the current directory:${NC}"
        for file in "${found_txt_files[@]}"; do
            echo -e "${RED}  - $(basename "$file") ${NC}"
        done
        echo -e "${RED}Please remove these files before running the script without the -s or -n options.${NC}"
        exit 1
    fi

########## Step 1: Batch File Creation ##########
cat > "$current_dir/html_file.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Batch File Editor</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        table, th, td {
            border: 1px solid #666;
        }
        th, td {
            padding: 8px;
            text-align: center;
            min-width: 100px;
            position: relative;
        }
        select {
            width: 100%;
        }
        td.selected {
            background-color: #cce5ff;
        }
        th.index, td.index {
            background-color: #f1f1f1;
            font-weight: bold;
            width: 40px;
            max-width: 40px;
            min-width: 40px;
        }
        /* Apply gray background style to table headers */
        thead th {
            background-color: #f1f1f1;
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.4);
        }
        .modal-content {
            background-color: #fefefe;
            margin: 15% auto;
            padding: 20px;
            border: 1px solid #888;
            width: 50%;
            text-align: center;
            border-radius: 8px;
        }
        .modal-button {
            margin: 10px;
            padding: 10px 20px;
            cursor: pointer;
            border: none;
            border-radius: 5px;
            background-color: #4CAF50;
            color: white;
        }
        .modal-button:hover {
            background-color: #367c39;
        }
        #noButton {
            background-color: #f44336;
            color: white;
        }
        #noButton:hover {
            background-color: #d32f2f;
        }
    </style>
</head>
<body>
    <h1>Batch File Editor</h1>
    <p>Each Batch file should include a single amplicon and guide RNA sequence. For multiple amplicons and/or guides, create a Batch file for each.</p>
    <table id="dataTable">
        <thead>
            <tr>
                <th class="index">#</th>
                <th>fastq_r1</th>
                <th>fastq_r2</th>
                <th>n</th>
                <th>a</th>
                <th>an</th>
                <th>g</th>
                <th>gn</th>
                <th>DNA_F_or_R</th>
                <th>BE</th>
            </tr>
        </thead>
        <tbody>
        </tbody>
    </table>
    <button onclick="addRows()">Add Rows</button>
    <button onclick="removeRows()">Remove Rows</button>
    <button id="saveButton" onclick="saveTXT()">Save Batch File as TXT</button>
    <button id="newFileButton">Create New Batch File</button>

    <div id="newFileModal" class="modal">
        <div class="modal-content">
            <p>Are you sure you want to create a new batch file?</p>
            <button id="yesButton" class="modal-button">Yes</button>
            <button id="noButton" class="modal-button">No</button>
        </div>
    </div>

    <div style="margin-top: 30px;">
        <p style="font-size: 0.9em;"><b>CRISPRessoBatch Parameters:</b></p>
        <p style="font-size: 0.9em;">fastq_r1 = Fastq_r1 file name</p>
        <p style="font-size: 0.9em;">fastq_r2 = Fastq_r2 file name</p>
        <p style="font-size: 0.9em;">n = Output name of the report</p>
        <p style="font-size: 0.9em;">a = Amplicon sequence</p>
        <p style="font-size: 0.9em;">an = Amplicon name</p>
        <p style="font-size: 0.9em;">g = sgRNA sequence</p>
        <p style="font-size: 0.9em;">gn = sgRNA name</p>
        <p style="font-size: 0.9em;">DNA_F_or_R = Defines if the sgRNA was designed on the forward (F) or reverse (R) DNA strand</p>
        <p style="font-size: 0.9em;">BE = Base editor (ABE or CBE)</p>
    </div>

    <script>
        let undoStack = []; // Stores table states for undo functionality
        let selectionStart = null; // Keeps track of the start cell for range selection
        let copiedDataBlock = null; // Stores data for block paste operations

        // Event listener for Ctrl+Z (undo)
        document.addEventListener("keydown", function(e) {
            if (e.ctrlKey && (e.key === "z" || e.key === "Z")) {
                e.preventDefault();
                undo();
            }
        });

        // Saves the current state of the table to the undo stack
        function saveState() {
            const table = document.getElementById("dataTable");
            const state = [];
            for (let i = 0; i < table.rows.length; i++) {
                const rowData = [];
                const cells = table.rows[i].cells;
                for (let j = 0; j < cells.length; j++) {
                    const sel = cells[j].querySelector("select");
                    rowData.push(sel ? sel.value : cells[j].innerText.trim());
                }
                state.push(rowData);
            }
            undoStack.push(state);
        }

        // Restores the previous state from the undo stack
        function undo() {
            if (undoStack.length > 1) {
                undoStack.pop(); // Remove current state
                const prev = undoStack[undoStack.length - 1]; // Get previous state
                const table = document.getElementById("dataTable");
                for (let i = 0; i < table.rows.length; i++) {
                    const cells = table.rows[i].cells;
                    for (let j = 0; j < cells.length; j++) {
                        const sel = cells[j].querySelector("select");
                        if (sel) sel.value = prev[i][j];
                        else cells[j].innerText = prev[i][j];
                    }
                }
            }
        }

        // Creates a new table row with appropriate cells and event listeners
        function createRow(idx) {
            const tr = document.createElement("tr");
            const td0 = document.createElement("td");
            td0.className = "index";
            td0.innerText = idx;
            tr.appendChild(td0);
            // Columns remaining after 'q', 'w', 'wc' removal
            const cols = ["fastq_r1", "fastq_r2", "n", "a", "an", "g", "gn"];
            cols.forEach((col, i) => {
                const td = document.createElement("td");
                td.contentEditable = "true"; // Makes cell editable
                td.dataset.col = col; // Stores column name as data attribute
                td.addEventListener("click", cellClickHandler); // Handles cell selection
                td.addEventListener("keydown", cellKeydownHandler); // Handles keyboard navigation
                td.addEventListener("blur", function(e) {
                    saveState(); // Save state on cell blur
                    // Autofill for "a", "an", "g", "gn" columns
                    if (["a", "an", "g", "gn"].includes(col)) {
                        const row = e.target.parentElement;
                        const val = e.target.innerText.trim();
                        const colIndex = e.target.cellIndex;
                        // Fill same value down the column
                        for (let i = row.rowIndex + 1; i < document.getElementById("dataTable").rows.length; i++) {
                            const nextRow = document.getElementById("dataTable").rows[i];
                            const targetCell = nextRow.cells[colIndex];
                            if (targetCell) {
                                targetCell.innerText = val;
                            }
                        }
                        saveState(); // Save state after auto-filling
                    }
                });
                tr.appendChild(td);
            });

            // Add dropdown for DNA_F_or_R
            const tdStr = document.createElement("td");
            const selStr = document.createElement("select");
            ["", "F", "R"].forEach(v => {
                let o = document.createElement("option");
                o.value = v;
                o.text = v;
                selStr.appendChild(o);
            });
            selStr.addEventListener("change", () => {
                autofillColumn(8, selStr.value); // New column index for DNA_F_or_R (was 11)
                saveState();
            });
            selStr.addEventListener("click", cellClickHandler);
            selStr.addEventListener("keydown", cellKeydownHandler);
            tdStr.appendChild(selStr);
            tr.appendChild(tdStr);

            // Add dropdown for BE (Base Editor)
            const tdBE = document.createElement("td");
            const selBE = document.createElement("select");
            ["", "ABE", "CBE"].forEach(v => {
                let o = document.createElement("option");
                o.value = v;
                o.text = v;
                selBE.appendChild(o);
            });
            selBE.addEventListener("change", () => {
                autofillColumn(9, selBE.value); // New column index for BE (was 12)
                saveState();
            });
            selBE.addEventListener("click", cellClickHandler);
            selBE.addEventListener("keydown", cellKeydownHandler);
            tdBE.appendChild(selBE);
            tr.appendChild(tdBE);
            return tr;
        }

        // Autofills a specific column with a given value for all rows
        function autofillColumn(ci, val) {
            document.querySelectorAll("#dataTable tbody tr").forEach(r => {
                const c = r.cells[ci];
                if (c) {
                    const s = c.querySelector("select");
                    if (s) s.value = val;
                    else c.innerText = val;
                }
            });
        }

        // Handles cell click events for selection
        function cellClickHandler(e) {
            if (e.shiftKey && selectionStart) selectRange(selectionStart, e.currentTarget);
            else {
                clearSelection();
                markSelected(e.currentTarget);
                selectionStart = e.currentTarget;
            }
        }

        // Selects a range of cells given a start and end cell
        function selectRange(s, e) {
            clearSelection();
            const t = document.getElementById("dataTable");
            const r1 = s.parentElement.rowIndex,
                c1 = s.cellIndex,
                r2 = e.parentElement.rowIndex,
                c2 = e.cellIndex;
            const rmin = Math.min(r1, r2),
                rmax = Math.max(r1, r2),
                cmin = Math.min(c1, c2),
                cmax = Math.max(c1, c2);
            for (let i = rmin; i <= rmax; i++) {
                for (let j = cmin; j <= cmax; j++) {
                    t.rows[i].cells[j].classList.add("selected");
                }
            }
        }

        // Clears all currently selected cells
        function clearSelection() {
            document.querySelectorAll("td.selected").forEach(td => td.classList.remove("selected"));
        }

        // Marks a single cell as selected
        function markSelected(c) {
            clearSelection();
            c.classList.add("selected");
        }

        // Handles keyboard navigation (arrows) within table cells
        function cellKeydownHandler(e) {
            let c = e.currentTarget.tagName === "TD" ? e.currentTarget : e.currentTarget.parentElement;
            const tr = c.parentElement,
                ci = c.cellIndex;
            let target = null;
            if (e.key === "ArrowRight" && c.nextElementSibling) target = c.nextElementSibling;
            if (e.key === "ArrowLeft" && c.previousElementSibling) target = c.previousElementSibling;
            if (e.key === "ArrowDown" && tr.nextElementSibling) target = tr.nextElementSibling.cells[ci];
            if (e.key === "ArrowUp" && tr.previousElementSibling) target = tr.previousElementSibling.cells[ci];
            if (target) {
                e.preventDefault();
                if (e.shiftKey && selectionStart) selectRange(selectionStart, target);
                else {
                    clearSelection();
                    markSelected(target);
                    selectionStart = target;
                }
                if (target.isContentEditable) target.focus();
                else {
                    const s = target.querySelector("select");
                    if (s) s.focus();
                }
            }
        }

        // Handles Ctrl+C (copy) functionality
        document.addEventListener("keydown", function(e) {
            if (e.ctrlKey && (e.key === "c" || e.key === "C")) {
                const sels = document.querySelectorAll("td.selected");
                if (sels.length) {
                    let rmin = Infinity,
                        rmax = -1,
                        cmin = Infinity,
                        cmax = -1;
                    sels.forEach(cell => {
                        const ri = cell.parentElement.rowIndex,
                            ci = cell.cellIndex;
                        rmin = Math.min(rmin, ri);
                        rmax = Math.max(rmax, ri);
                        cmin = Math.min(cmin, ci);
                        cmax = Math.max(cmax, ci);
                    });
                    let block = [],
                        txt = "";
                    const tbl = document.getElementById("dataTable");
                    for (let i = rmin; i <= rmax; i++) {
                        let row = [];
                        for (let j = cmin; j <= cmax; j++) {
                            let cell = tbl.rows[i].cells[j];
                            let v = cell.querySelector("select") ? cell.querySelector("select").value : cell.innerText.trim();
                            row.push(v);
                        }
                        block.push(row);
                        txt += row.join("\t") + "\n";
                    }
                    copiedDataBlock = block;
                    e.preventDefault();
                    navigator.clipboard.writeText(txt);
                }
            }
        });

        // Handles Delete key to clear selected cells
        document.addEventListener("keydown", function(e) {
            if (e.key === "Delete") {
                document.querySelectorAll("td.selected").forEach(cell => {
                    const s = cell.querySelector("select");
                    if (s) {
                        s.value = "";
                        s.dispatchEvent(new Event("change"));
                    } else cell.innerText = "";
                });
                saveState();
            }
        });

        // Handles paste event (Ctrl+V)
        document.addEventListener("paste", function(e) {
            const tbl = document.getElementById("dataTable");
            let active = document.activeElement;
            let cur = active.tagName === "TD" && active.isContentEditable ? active : (active.tagName === "SELECT" ? active.parentElement : null);
            if (!cur) return; // If no active cell or it's not a relevant cell for pasting
            const sr = cur.parentElement.rowIndex, // Start row index
                sc = cur.cellIndex; // Start column index

            // The select columns (DNA_F_or_R and BE) are now at index 8 and 9.
            // Editable text columns end at index 7 (gn).
            if (sc >= 8) { // If the selected cell is a select dropdown, prevent pasting.
                alert("Paste not allowed in this column.");
                e.preventDefault();
                return;
            }

            if (copiedDataBlock) { // If data was copied from within the table
                copiedDataBlock.forEach((row, i) => {
                    let tr = tbl.rows[sr + i];
                    if (!tr) return; // If target row doesn't exist
                    row.forEach((v, j) => {
                        let cell = tr.cells[sc + j];
                        // Ensure pasting only occurs in the remaining editable text columns
                        if (cell && cell.cellIndex < 8) {
                            let s = cell.querySelector("select");
                            if (s) s.value = v; // Should not happen for text cells, but good for robustness
                            else cell.innerText = v;
                        }
                    });
                });
                saveState();
                e.preventDefault();
            } else { // If data is pasted from external source (e.g., spreadsheet)
                const data = (e.clipboardData || window.clipboardData).getData("Text");
                const rows = data.split("\n").filter(l => l.trim());
                rows.forEach((r, i) => {
                    const vals = r.split("\t");
                    let tr = tbl.rows[sr + i];
                    if (tr) vals.forEach((v, j) => {
                        let cell = tr.cells[sc + j];
                        // Ensure pasting only occurs in the remaining editable text columns
                        if (cell && cell.cellIndex < 8) {
                            let s = cell.querySelector("select");
                            if (s) s.value = v.trim();
                            else cell.innerText = v.trim();
                        }
                    });
                });
                saveState();
                e.preventDefault();
            }
        });

        // Validates the content of the table cells against defined regex patterns
        function validateTable() {
            const regexes = {
                1: /^[A-Za-z0-9._-]+$/, // fastq_r1
                2: /^[A-Za-z0-9._-]+$/, // fastq_r2
                3: /^[A-Za-z0-9_-]+$/,  // n
                4: /^[A-Za-z]+$/,       // a
                5: /^[A-Za-z0-9_-]+$/,  // an
                6: /^[A-Za-z]+$/,       // g
                7: /^[A-Za-z0-9_-]+$/   // gn
                // Validations for 'q', 'w', 'wc' columns removed
            };
            const names = {
                1: "fastq_r1",
                2: "fastq_r2",
                3: "n",
                4: "a",
                5: "an",
                6: "g",
                7: "gn"
                // Names for 'q', 'w', 'wc' columns removed
            };
            const tbl = document.getElementById("dataTable");
            let errs = [];
            for (let i = 0; i < tbl.tBodies[0].rows.length; i++) {
                let row = tbl.tBodies[0].rows[i];
                // Loop through the remaining editable data columns (index 1 to 7)
                for (let j = 1; j <= 7; j++) {
                    let val = row.cells[j].innerText.trim();
                    if (!val) continue; // Skip empty cells for validation (allow empty initially)
                    let re = regexes[j];
                    if (re && !re.test(val)) {
                        let invalidChars = [];
                        for (let char of val) {
                            if (!re.test(char)) {
                                invalidChars.push(`"${char}"`);
                            }
                        }
                        errs.push(`Row ${i+1}, ${names[j]}, Invalid character(s): ${invalidChars.join(", ")}`);
                    }
                }
            }
            if (errs.length) {
                alert("Invalid characters found:\n" + errs.join("\n"));
                return false;
            }
            return true;
        }

        // Saves the table data as a tab-separated TXT file
        function saveTXT() {
            if (!validateTable()) return; // Validate before saving

            const tbl = document.getElementById("dataTable");
            let txt = "";
            // Filter headers to exclude 'q', 'w', 'wc'
            let headers = Array.from(tbl.tHead.rows[0].cells)
                              .slice(1) // Skip the '#' index column
                              .filter(c => !['q', 'w', 'wc'].includes(c.innerText.trim())) // Filter out unwanted column headers
                              .map(c => c.innerText.trim());
            txt += headers.join("\t") + "\n";

            for (let i = 0; i < tbl.tBodies[0].rows.length; i++) {
                let cells = tbl.tBodies[0].rows[i].cells;
                let rowData = [];
                // Iterate through cells, skipping 'q', 'w', 'wc' based on header text
                for (let j = 1; j < cells.length; j++) {
                    const headerText = tbl.tHead.rows[0].cells[j].innerText.trim();
                    if (['q', 'w', 'wc'].includes(headerText)) {
                        continue; // Skip these columns
                    }
                    let c = cells[j];
                    let s = c.querySelector("select");
                    rowData.push(s ? s.value : c.innerText.trim());
                }

                if (rowData.includes("")) {
                    alert("Please fill in all cells before saving.");
                    return;
                }
                txt += rowData.join("\t") + "\n";
            }
            // Create a Blob and a download link for the TXT file
            const blob = new Blob([txt], {
                type: "text/plain;charset=utf-8;"
            });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "batch_file.txt";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // Event listener when the DOM is fully loaded
        window.addEventListener("DOMContentLoaded", () => {
            const tb = document.querySelector("#dataTable tbody");
            tb.appendChild(createRow(1)); // Add initial row
            saveState(); // Save initial state

            const newFileButton = document.getElementById("newFileButton");
            const newFileModal = document.getElementById("newFileModal");
            const yesButton = document.getElementById("yesButton");
            const noButton = document.getElementById("noButton");

            // Show new file confirmation modal
            newFileButton.addEventListener("click", () => {
                newFileModal.style.display = "block";
            });

            // Handle 'Yes' for new file: clear table and add one row
            yesButton.addEventListener("click", () => {
                const tb = document.querySelector("#dataTable tbody");
                while (tb.firstChild) {
                    tb.removeChild(tb.firstChild);
                }
                tb.appendChild(createRow(1));
                saveState();
                newFileModal.style.display = "none";
            });

            // Handle 'No' for new file: close modal
            noButton.addEventListener("click", () => {
                newFileModal.style.display = "none";
            });

            // Close modal if clicked outside
            window.addEventListener("click", (event) => {
                if (event.target === newFileModal) {
                    newFileModal.style.display = "none";
                }
            });
        });

        // Adds new rows to the table, optionally autofilling from the last row
        function addRows() {
            const n = parseInt(prompt("How many rows to add?", "1"));
            if (!isNaN(n) && n > 0) {
                const tb = document.querySelector("#dataTable tbody");
                const c = tb.rows.length; // Current number of rows

                for (let i = 0; i < n; i++) {
                    const newRow = createRow(c + i + 1);
                    // Autofill based on the last existing row
                    if (c > 0) {
                        const lastRow = tb.rows[c - 1]; // Get the last row before adding new ones
                        // Columns to autofill (indices in the new table structure):
                        // 'a' (index 4), 'an' (index 5), 'g' (index 6), 'gn' (index 7),
                        // 'DNA_F_or_R' (index 8), 'BE' (index 9)
                        const colsToAutofill = [4, 5, 6, 7, 8, 9]; 

                        colsToAutofill.forEach(colIndex => {
                            const lastCell = lastRow.cells[colIndex];
                            const newCell = newRow.cells[colIndex];
                            if (lastCell && newCell) {
                                let lastValue;
                                // Get value from select or innerText
                                if (lastCell.querySelector("select")) {
                                    lastValue = lastCell.querySelector("select").value;
                                } else {
                                    lastValue = lastCell.innerText.trim();
                                }

                                // Apply value to new cell (select or innerText)
                                if (newCell.querySelector("select")) {
                                    newCell.querySelector("select").value = lastValue;
                                } else {
                                    newCell.innerText = lastValue;
                                }
                            }
                        });
                    }
                    tb.appendChild(newRow);
                }
                saveState();
            }
        }

        // Removes rows from the table
        function removeRows() {
            const tb = document.querySelector("#dataTable tbody");
            const n = parseInt(prompt("How many rows to remove?", "1"));
            if (!isNaN(n) && n > 0) {
                // Delete rows from the end of the table
                for (let i = 0; i < n && tb.rows.length > 0; i++) tb.deleteRow(-1);
                saveState();
            } else alert("Please enter a valid number.");
        }
    </script>
</body>
</html>
EOF

open_html_file() {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        open -a "Google Chrome" html_file.html || {
            echo -e "${RED}Error: Unable to open Google Chrome. Is it installed?${NC}"
            exit 1
        }
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome html_file.html 2>/dev/null &
    elif command -v google-chrome-stable >/dev/null 2>&1; then
        google-chrome-stable html_file.html 2>/dev/null &
    else
        echo -e "${RED}Error: Google Chrome is not installed or not found in your PATH. Please install Google Chrome to proceed with the Batch file editing.${NC}"
        exit 1
    fi
}

echo
echo -e "${NC}Opening the Batch file (html_file.html) in Google Chrome.${NC}"
echo -e "${NC}Please fill in the required information and save the file.${NC}"
echo
open_html_file

    while true; do
        read -p "Do you want to continue with the CRISPResso2 analysis? (yes/y to continue, no/n to abort) " continue_analysis_input
        case "$continue_analysis_input" in
            [Yy][Ee][Ss]|[Yy])
                # After HTML completion, re-search for .txt files in the current directory.
                found_txt_files=()
                for file in "$current_dir"/*.txt; do
                    if [ -e "$file" ]; then
                        found_txt_files+=("$file")
                    fi
                done
                if [ ${#found_txt_files[@]} -eq 0 ]; then
                    echo -e "${RED}Error: No .txt files found after HTML completion. Cannot continue CRISPResso2 analysis.${NC}"
                    exit 1
                fi    
                break # Exit the loop if input is valid for continuation
                ;;
            [Nn][Oo]|[Nn])
                echo -e "${NC}Aborting script as requested.${NC}"
                exit 0 # Exit the script if user chooses to abort
                ;;
            *)
                echo -e "${RED}Invalid option \"${continue_analysis_input}\". Please enter 'yes/y' to continue or 'no/n' to abort.${NC}"
                ;;
        esac
    done
fi

# Column + value validation (accumulate errors and exit at the end)
# Initialize an error counter for column-related issues.
declare -i COLUMN_ERROR=0

# Define the list of required columns.
REQUIRED_COLUMNS=(
    fastq_r1 fastq_r2 n a an g gn
    DNA_F_or_R BE
)

# Declare an associative array for regex patterns for each column.
declare -A regexes=(
    [fastq_r1]='^[A-Za-z0-9._-]+$'
    [fastq_r2]='^[A-Za-z0-9._-]+$'
    [n]='^[A-Za-z0-9_-]+$'
    [a]='^[A-Za-z]+$'
    [an]='^[A-Za-z0-9_-]+$'
    [g]='^[A-Za-z]+$'
    [gn]='^[A-Za-z0-9_-]+$'
    [DNA_F_or_R]='^(F|R)$'
    [BE]='^(ABE|CBE)$'
)

# Columns that must have the same value across all rows.
# These values will be validated for repetition.
REQUIRED_REPEATED_COLUMNS=(
    a an g gn DNA_F_or_R BE
)

# Loop through each found text file to perform validation.
for file in "${found_txt_files[@]}"; do
    echo -e "${NC}Checking file: $(basename "$file")...${NC}"
    
    # Read the header line from the current file.
    header=$(head -n 1 "$file")
    # Split the header into an array of column names using tab as a delimiter.
    IFS=$'\t' read -ra columns <<< "$header"
    unset IFS # Unset IFS to revert to default behavior

    # Header validation: determine missing and invalid columns
    missing=() # Array to store missing required columns
    invalid=() # Array to store invalid/unexpected columns in the header

    # Check for missing required columns.
    for req in "${REQUIRED_COLUMNS[@]}"; do
        if [[ ! " ${columns[@]} " =~ " ${req} " ]]; then
            missing+=("$req") # Add to missing list if not found
        fi
    done

    # Check for invalid/unexpected columns in the file's header.
    for col in "${columns[@]}"; do
        if [[ ! " ${REQUIRED_COLUMNS[*]} " =~ " ${col} " ]]; then
            invalid+=("$col") # Add to invalid list if not a required column
        fi
    done

    # Report header errors.
    if (( ${#missing[@]} )); then
        echo -e "${RED}Error in $(basename "$file"): missing columns: ${missing[*]}${NC}"
        ((COLUMN_ERROR++))
    fi
    if (( ${#invalid[@]} )); then
        echo -e "${RED}Error in $(basename "$file"): invalid columns: ${invalid[*]}${NC}"
        ((COLUMN_ERROR++))
    fi

    # Value validation (only proceed if there were no header errors)
    if (( ${#missing[@]} == 0 && ${#invalid[@]} == 0 )); then
        # Build a column name to index mapping for efficient value retrieval.
        declare -A col_idx=()
        for i in "${!columns[@]}"; do
            col_idx["${columns[i]}"]=$i
        done

        # Declare an associative array to store the expected (first row) values for repeated columns.
        declare -A first_row_values=()
        declare -i is_first_data_row=1 # Flag to identify the first data row

        LINE_NUM=1 # Initialize line number, starting after the header
        # Read the file line by line, skipping the header (tail -n +2).
        while IFS=$'\t' read -ra values; do
            LINE_NUM=$((LINE_NUM+1)) # Increment line number for current row

            # --- Individual cell value validation (using regex) ---
            for req in "${REQUIRED_COLUMNS[@]}"; do
                val="${values[${col_idx[$req]}]}" # Get the value for the current required column

                regex="${regexes[$req]}"
                if ! [[ $val =~ $regex ]]; then
                    echo -e "${RED}Error in $(basename "$file"), line $LINE_NUM, col '$req': Invalid value '$val'${NC}"
                    ((COLUMN_ERROR++))
                fi
            done

            # Repetition validation for specific columns
            for rep_col in "${REQUIRED_REPEATED_COLUMNS[@]}"; do
                current_val="${values[${col_idx[$rep_col]}]}"

                if (( is_first_data_row == 1 )); then
                    # If this is the first data row, store its values as the reference.
                    first_row_values["$rep_col"]="$current_val"
                else
                    # For subsequent rows, compare with the stored first row value.
                    if [[ "${first_row_values[$rep_col]}" != "$current_val" ]]; then
                        echo -e "${RED}Error in $(basename "$file"), line $LINE_NUM, col '$rep_col': Value '$current_val' must match the first row's value '${first_row_values[$rep_col]}'${NC}"
                        ((COLUMN_ERROR++))
                    fi
                fi
            done
            is_first_data_row=0 # After processing the first data row, set the flag to 0.
        done < <(tail -n +2 "$file") # Process file content starting from the second line
    fi
done

# If any errors were found, exit
if (( COLUMN_ERROR )); then
    echo -e "${RED}Validation failed (${COLUMN_ERROR} error(s)).${NC}"
    exit 1
else
    echo -e "${NC}All .txt files passed header and value validation.${NC}"
fi

########## Step 2: Execution of CRISPResso2 ##########
if $run_crispresso; then
    echo -e "${NC}Running CRISPResso2...${NC}"
    # Iterate over all .txt files in the current directory
    current_dir=$(pwd) # Get the current directory
    for file in "$current_dir"/*.txt; do
        # Check if the file exists and is a regular file
        if [[ -f "$file" ]]; then
            echo -e "\n${NC}Running CRISPResso2 for: $(basename "$file")...${NC}"

            # Get the header and the first data row of the file
            header=$(head -n 1 "$file")
            first_data_row=$(sed -n '2p' "$file") # Get the second line (first data row)

            # Split the header into an array to find column indices
            IFS=$'\t' read -ra columns <<< "$header"
            unset IFS # Restore default IFS

            # Create an associative array to map column names to their indices
            declare -A col_idx=()
            for i in "${!columns[@]}"; do
                col_idx["${columns[i]}"]=$i
            done

            # Get values from the first data row
            IFS=$'\t' read -ra values <<< "$first_data_row"
            unset IFS # Restore default IFS

            # Extract values from columns 'g' and 'DNA_F_or_R'
            # Make sure the columns 'g' and 'DNA_F_or_R' exist in your file
            if [[ -z "${col_idx['g']}" || -z "${col_idx['DNA_F_or_R']}" ]]; then
                echo -e "${RED}ERROR: Columns 'g' or 'DNA_F_or_R' not found in file $(basename "$file").${NC}"
                continue # Skip to the next file
            fi

            g_value="${values[${col_idx['g']}]}"
            dna_f_or_r_value="${values[${col_idx['DNA_F_or_R']}]}" 

            # Calculate the length of the 'g' value
            g_length=${#g_value}

            # Initialize w_val_float and wc_val_float as floating-point numbers
            w_val_float=0.0
            wc_val_float=0.0

            # Logic to calculate w and wc based on the length of 'g' and 'DNA_F_or_R'
            if (( g_length % 2 == 0 )); then
                # Even length: w is half the length, wc is the negative of w
                w_val_float=$(echo "scale=1; $g_length / 2" | bc)
                wc_val_float=$(echo "scale=1; -$w_val_float" | bc)
            else
                # Odd length: check the DNA_F_or_R column
                if [[ "$dna_f_or_r_value" == "R" ]]; then
                    # If R: w is half of g_length + 0.5, wc is half of g_length - 0.5 (negative)
                    w_val_float=$(echo "scale=1; $g_length / 2 + 0.5" | bc)
                    wc_val_float=$(echo "scale=1; ($g_length / 2 - 0.5)" | bc)
                    wc_val_float=$(echo "scale=1; -$wc_val_float" | bc) # Ensure wc is negative
                elif [[ "$dna_f_or_r_value" == "F" ]]; then
                    # If F: w is half of g_length + 0.5, wc is the same value but negative
                    w_val_float=$(echo "scale=1; $g_length / 2 + 0.5" | bc)
                    wc_val_float=$(echo "scale=1; -$w_val_float" | bc)
                else
                    echo -e "${RED}WARNING: Unexpected value for DNA_F_or_R ('$dna_f_or_r_value') in file $(basename "$file"). Skipping this file.${NC}"
                    continue # Skip to the next file if value is unexpected
                fi
            fi

            # Format w_val and wc_val to always be integers by rounding
            w_val=$(printf "%.0f" "$w_val_float")
            wc_val=$(printf "%.0f" "$wc_val_float")

            # Handle negative zero for wc_val (e.g., -0.0 becomes 0)
            if [[ "$wc_val" == "-0" ]]; then
                wc_val="0"
            fi

            # Define the CRISPRessoBatch command with the calculated values
            cmd=(CRISPRessoBatch --batch_settings "$file" -q 30 -w "$w_val" -wc "$wc_val")

            # Append any custom options provided by the user
            if (( ${#custom_opts[@]} )); then
                cmd+=("${custom_opts[@]}")
            fi

            echo -e "${NC}Command: ${cmd[*]}${NC}\n"
            "${cmd[@]}" # Execute the command

            # Check the exit status of the CRISPRessoBatch command
            if (( $? != 0 )); then
                echo -e "${RED}ERROR: CRISPResso2 failed on $(basename "$file").${NC}"
                exit 1 # Exit if CRISPResso2 encountered an error
            fi
        else
            echo -e "${RED}WARNING: File not found or not a regular file: $file. Skipping.${NC}"
        fi
    done
    echo -e "\n${NC}CRISPResso2 analysis completed successfully.${NC}\n"
fi

########## Step 3: Downstream analysis ##########
if ! $open_html && ! $run_crispresso; then
    echo -e "\n${NC}Starting base editing, indel calculation and heatmap creation...${NC}\n"
else
    display_footer
    echo -e "\n${NC}Starting base editing, indel calculation and heatmap creation...${NC}\n"
fi


# Create the Rmd file
cat > "$current_dir/temp_script.Rmd" <<'EOF'
---
title: "Base Editing Analysis"
output: html_document
params:
  normal_matrix: NULL
  inverted_matrix: NULL
  base_editing: NULL
---


```{r}
#################################################################################      
# Fast Analyzr BE  general informations CBE  
#################################################################################  

library(openxlsx)
library(png)
library(readxl)
library(ggplot2)
library(tidyr)
library(dplyr)
library(ggtext)

# Checks if parameters were passed
if (is.null(params$normal_matrix)) {
  stop("Error: 'normal_matrix' parameter is required.")
}

if (is.null(params$inverted_matrix)) {
  stop("Error: 'inverted_matrix' parameter is required.")
}

if (is.null(params$base_editing)) {
  stop("Error: 'base_editing' parameter is required.")
}

# Uses the parameters passed in the terminal
normal_matrix <- params$normal_matrix
inverted_matrix <- params$inverted_matrix
base_editing <- params$base_editing

# Displays the loaded parameters
print(paste("Normal Matrix:", paste(normal_matrix, collapse = ", ")))
print(paste("Inverted Matrix:", paste(inverted_matrix, collapse = ", ")))
print("Base Editing Mapping:")
print(base_editing)

#################################################################################
# Initial analysis
#################################################################################

if(!dir.exists("Final_result")) {
  dir.create("Final_result")
}

# Load all .txt files in the current directory
files_txt <- list.files(pattern = "\\.txt$", full.names = TRUE)

# Loop to process each file
for (file in files_txt) {
  
  # Display the name of the file being processed
  cat("Processing file:", file, "\n")
  
  # Read the file
  dataframe <- read.delim(file, sep = "\t", header = TRUE)
  
  # Remove the file extension
  base_name <- tools::file_path_sans_ext(basename(file))
  
  # Create the folder name
  folder <- paste0("CRISPRessoBatch_on_", base_name)
  
  # Check if the folder exists; if not, create it
  if (!dir.exists(folder)) {
    dir.create(folder)
  }
  
  # Set as working directory
  setwd(folder)
  
  #################################################################################
  # Edition analysis
  #################################################################################
  
  # Initialize an empty data frame to store the final results
  final_results_edition <- data.frame()
  
  # Iterate over all rows of the `dataframe` to process the results
  for (i in 1:nrow(dataframe)) {
    
    # Get the values from the columns `n`, `an`, and `gn` to create the file name
    base_name_sample <- dataframe$n[i]
    prefix_an <- dataframe$an[i]
    gn_base <- dataframe$gn[i]
    
    # Create the folder name
    folder_sample <- paste0("CRISPResso_on_", base_name_sample)
    
    # Build the dynamic file name based on the `an` column
    file_name <- paste0(prefix_an, ".Quantification_window_nucleotide_percentage_table.txt")
    
    # Build the path to the specific file
    file_derived <- file.path(folder_sample, file_name)
    
    # Read the file without altering the column names
    derived_data <- read.delim(file_derived, sep = "\t", row.names = 1, header = TRUE, check.names = FALSE)
    
    # Get the specific editing type for the guide using the mapping
    be_for_sample <- base_editing[gn_base]
    if (is.null(be_for_sample) || length(be_for_sample) == 0) {
      warning(paste("Editing type not found for guide", gn_base, "- using default (ABE)"))
      be_for_sample <- "ABE"
    }
    
    # Processes according to the specific editing type
    if (be_for_sample == "CBE") {
      
      if (gn_base %in% inverted_matrix) {    
        # Inverted matrix for CBE
        derived_data <- derived_data[, ncol(derived_data):1]  # Inverts the column order
        
        # Selects all columns that start with "G"
        columns_G <- grep("^G", colnames(derived_data), value = TRUE)
        
        # Gets the column indexes
        indexes_columns_G <- match(columns_G, colnames(derived_data))
        
        # Accesses the values of row "A" for the selected columns
        vls_G_A <- derived_data["A", columns_G]
        
        # Converts the values to percentages
        vls_G_A_percentual <- vls_G_A * 100    
        
        # Creates a formatted string
        formatted_result <- paste0("G", indexes_columns_G, " = ", round(vls_G_A_percentual, 2), "%")
        
        # Separates the numbers and percentage values
        split_result <- strsplit(formatted_result, " = ")
        T_values <- gsub("G", "", sapply(split_result, `[`, 1))
        percent_values <- sapply(split_result, `[`, 2)
        percent_values_numeric <- as.numeric(gsub("%", "", percent_values))
        
        # Creates a data frame with the percentage values
        result_df_edition <- data.frame(matrix(percent_values_numeric, nrow = 1))
        colnames(result_df_edition) <- paste0("C", T_values)
        
        # Adds the sample name to the first column "Samples"
        result_df_edition$Samples <- base_name_sample
        
        # Reorders the columns so that "Samples" is on the left
        result_df_edition <- result_df_edition[, c("Samples", colnames(result_df_edition)[1:(ncol(result_df_edition)-1)])]
        
        # Adds the results to the final data frame
        final_results_edition <- rbind(final_results_edition, result_df_edition)
        
      } else if (gn_base %in% normal_matrix) {
        # Normal matrix for CBE
        line_G <- as.numeric(derived_data["T", ])    
        
        # Identifies columns that contain "C"
        columns_A <- colnames(derived_data)[grepl("C", colnames(derived_data))]
        
        # Filters the values from row "T" for columns that contain "C"
        values_A <- line_G[grepl("C", colnames(derived_data))]
        
        # Gets the real positions of the columns
        positions_A <- which(grepl("C", colnames(derived_data)))
        
        # Adjusts column names to include position, e.g., "C1", "C2"
        columns_A_adjusted <- paste0("C", positions_A)
        
        # Converts values to percentages
        values_A_percentage <- round(values_A * 100, 2)
        
        # Creates a data frame for this sample
        sample_result <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(values_A_percentage)), columns_A_adjusted)
        )
        
        # Adds the results to the final data frame
        final_results_edition <- rbind(final_results_edition, sample_result)
      }
      
    } else if (be_for_sample == "ABE") {
      
      if (gn_base %in% inverted_matrix) {
        # Inverted matrix for ABE
        derived_data <- derived_data[, ncol(derived_data):1]  # Inverts the column order
        
        # Selects all columns that start with "T"
        columns_T <- grep("^T", colnames(derived_data), value = TRUE)
        
        # Gets the column indexes
        indexes_columns_T <- match(columns_T, colnames(derived_data))
        
        # Accesses the values of row "C" for the selected columns
        vls_T_C <- derived_data["C", columns_T]
        
        # Converts the values to percentages
        vls_T_C_percentual <- vls_T_C * 100
        
        # Creates a formatted string
        formatted_result <- paste0("T", indexes_columns_T, " = ", round(vls_T_C_percentual, 2), "%")
        
        # Separates the numbers and percentage values
        split_result <- strsplit(formatted_result, " = ")
        T_values <- gsub("T", "", sapply(split_result, `[`, 1))
        percent_values <- sapply(split_result, `[`, 2)
        percent_values_numeric <- as.numeric(gsub("%", "", percent_values))
        
        # Creates a data frame with the percentage values
        result_df_edition <- data.frame(matrix(percent_values_numeric, nrow = 1))
        colnames(result_df_edition) <- paste0("A", T_values)
        
        # Adds the sample name to the first column "Samples"
        result_df_edition$Samples <- base_name_sample
        
        # Reorders the columns so that "Samples" is on the left
        result_df_edition <- result_df_edition[, c("Samples", colnames(result_df_edition)[1:(ncol(result_df_edition)-1)])]
        
        # Adds the results to the final data frame
        final_results_edition <- rbind(final_results_edition, result_df_edition)
        
      } else if (gn_base %in% normal_matrix) {
        # Normal matrix for ABE
        line_G <- as.numeric(derived_data["G", ])
        
        # Identifies columns that contain "A"
        columns_A <- colnames(derived_data)[grepl("A", colnames(derived_data))]
        
        # Filters the values from row "G" for columns that contain "A"
        values_A <- line_G[grepl("A", colnames(derived_data))]
        
        # Gets the real positions of the columns
        positions_A <- which(grepl("A", colnames(derived_data)))
        
        # Adjusts column names to include position, e.g., "A1", "A2"
        columns_A_adjusted <- paste0("A", positions_A)
        
        # Converts values to percentages
        values_A_percentage <- round(values_A * 100, 2)
        
        # Creates a data frame for this sample
        sample_result <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(values_A_percentage)), columns_A_adjusted)
        )
        
        # Adds the results to the final data frame
        final_results_edition <- rbind(final_results_edition, sample_result)
      }
    }
  }
  
  #################################################################################
  # Final Edition Analysis Total
  #################################################################################
  
  # Initialize an empty data frame to store the final results
  final_results_edition_total <- data.frame()
  
  # Function to replace nucleotides with complementary ones
  replace_complementary <- function(name_column) {
    # Extracts the nucleotide and number
    nucleotide <- substr(name_column, 1, 1)
    number <- substr(name_column, 2, nchar(name_column))
    
    # Replaces with the complementary nucleotide
    complementary <- switch(nucleotide,
                            "A" = "T",                    
                            "T" = "A",
                            "C" = "G",
                            "G" = "C",
                            nucleotide)  # If not A, T, C, or G, keeps the original
    
    # Returns the column name with the complementary
    return(paste0(complementary, number))
  }
  
  # Iterates over all rows of the dataframe to process the total results
  for (i in 1:nrow(dataframe)) {
    
    base_name_sample <- dataframe$n[i]
    prefix_an <- dataframe$an[i]
    gn_base <- dataframe$gn[i]
    
    folder_sample <- paste0("CRISPResso_on_", base_name_sample)
    file_name <- paste0(prefix_an, ".Quantification_window_nucleotide_percentage_table.txt")
    file_derived <- file.path(folder_sample, file_name)
    
    derived_data <- read.delim(file_derived, sep = "\t", row.names = 1, header = TRUE, check.names = FALSE)
    
    # Gets the specific editing type for the guide
    be_for_sample <- base_editing[gn_base]
    if (is.null(be_for_sample) || length(be_for_sample) == 0) {
      warning(paste("Editing type not found for guide", gn_base, "- using default (ABE)"))
      be_for_sample <- "ABE"
    }
    
    if (be_for_sample == "CBE") {
      
      if (gn_base %in% inverted_matrix) {
        # Inverted matrix for CBE
        derived_data <- derived_data[, ncol(derived_data):1]  # Inverts the column order
        
        # Uses row "A"
        line_C <- as.numeric(derived_data["A", ])    
        
        # Identifies all columns
        all_columns <- colnames(derived_data)
        
        # Gets the real positions of the columns
        positions_columns <- 1:length(all_columns)
        
        # Adjusts column names to include the position
        columns_adjusted <- paste0(substr(all_columns, 1, 1), positions_columns)
        
        # Replaces nucleotides with complementary ones
        columns_adjusted <- sapply(columns_adjusted, replace_complementary)
        
        # Converts values to percentages
        vls_C_perct <- round(line_C * 100, 2)
        
        # Creates a data frame for this sample
        sample_result_total <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(vls_C_perct)), columns_adjusted),
          stringsAsFactors = FALSE
        )
        
        # Replaces values in columns that do not start with "C" with NA (except "Samples")
        for (column in colnames(sample_result_total)) {
          if (!startsWith(column, "C") & column != "Samples") {
            sample_result_total[[column]] <- NA
          }
        }
        
        final_results_edition_total <- rbind(final_results_edition_total, sample_result_total)
        
      } else if (gn_base %in% normal_matrix) {
        # Normal matrix for CBE
        line_G <- as.numeric(derived_data["T", ])
        
        all_columns <- colnames(derived_data)
        positions_columns <- 1:length(all_columns)
        columns_adjusted <- paste0(substr(all_columns, 1, 1), positions_columns)
        
        vls_G_perct <- round(line_G * 100, 2)
        
        sample_result_total <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(vls_G_perct)), columns_adjusted),
          stringsAsFactors = FALSE
        )
        
        for (column in colnames(sample_result_total)) {
          if (!startsWith(column, "C") & column != "Samples") {
            sample_result_total[[column]] <- NA
          }
        }
        
        final_results_edition_total <- rbind(final_results_edition_total, sample_result_total)
      }
    } else if (be_for_sample == "ABE") {
      
      if (gn_base %in% inverted_matrix) {
        # Inverted matrix for ABE
        derived_data <- derived_data[, ncol(derived_data):1]  # Inverts the column order
        
        # Uses row "C"
        line_C <- as.numeric(derived_data["C", ])
        
        all_columns <- colnames(derived_data)
        positions_columns <- 1:length(all_columns)
        columns_adjusted <- paste0(substr(all_columns, 1, 1), positions_columns)
        columns_adjusted <- sapply(columns_adjusted, replace_complementary)
        
        vls_C_perct <- round(line_C * 100, 2)
        
        sample_result_total <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(vls_C_perct)), columns_adjusted),
          stringsAsFactors = FALSE
        )
        
        for (column in colnames(sample_result_total)) {
          if (!startsWith(column, "A") & column != "Samples") {
            sample_result_total[[column]] <- NA
          }
        }
        
        final_results_edition_total <- rbind(final_results_edition_total, sample_result_total)
        
      } else if (gn_base %in% normal_matrix) {
        # Normal matrix for ABE
        line_G <- as.numeric(derived_data["G", ])
        
        all_columns <- colnames(derived_data)
        positions_columns <- 1:length(all_columns)
        columns_adjusted <- paste0(substr(all_columns, 1, 1), positions_columns)
        
        vls_G_perct <- round(line_G * 100, 2)
        
        sample_result_total <- data.frame(
          Samples = base_name_sample,
          setNames(as.data.frame(t(vls_G_perct)), columns_adjusted),
          stringsAsFactors = FALSE
        )
        
        for (column in colnames(sample_result_total)) {
          if (!startsWith(column, "A") & column != "Samples") {
            sample_result_total[[column]] <- NA
          }
        }
        
        final_results_edition_total <- rbind(final_results_edition_total, sample_result_total)
      }
    }
  } 

#################################################################################                                 
# Indel Analysis  
#################################################################################  

# Initialize a list to store the results
final_results_indel <- data.frame()

# Iterate over all rows of the `dataframe` dataframe to process the results
for (i in 1:nrow(dataframe)) {
  
  # Get the values from the `n`, `an`, and `gn` columns for the current sample
  base_name <- dataframe$n[i]
  an_base <- dataframe$an[i]
  gn_base <- dataframe$gn[i]
  
  # Build the file name based on the `an` and `gn` columns
  name_file <- paste0(an_base, ".Alleles_frequency_table_around_", gn_base, ".txt")
  
  # Create the full path to the file
  folder <- paste0("CRISPResso_on_", base_name)
  pth_file <- file.path(folder, name_file)
  
  # Read the .txt file without altering the column names and without treating '#' as a comment
  data <- read.table(pth_file, header = TRUE, sep = "\t", check.names = FALSE, row.names = NULL, comment.char = "")
  
  # Remove unwanted columns
  data <- subset(data, select = -c(Unedited, n_mutated))
  
  # Create the new column "sma" with the sum of the n_deleted and n_inserted columns
  data$sma <- data$n_deleted + data$n_inserted
  
  # Remove the rows where the "sma" column is equal to 0
  data <- subset(data, sma != 0)
  
  # Delete the "sma" column
  data <- subset(data, select = -sma)
  
  # Filter the values from the %Reads column for insertions and deletions
  data_insertion <- subset(data, n_inserted > 0)
  insertion_percentage <- sum(data_insertion$`%Reads`, na.rm = TRUE)
  insertion_reads <- sum(data_insertion$`#Reads`, na.rm = TRUE)
  
  data_deletion <- subset(data, n_deleted > 0)
  deletion_percentage <- sum(data_deletion$`%Reads`, na.rm = TRUE)
  deletion_reads <- sum(data_deletion$`#Reads`, na.rm = TRUE)
  
  # Calculate the total indels
  indel <- sum(insertion_percentage, deletion_percentage)
  
  # Create a dataframe to store the results for the sample
  result_df_indel <- data.frame(
    Samples = base_name,
    Insertion_Percentage = round(insertion_percentage, 2),
    Insertion_Reads = insertion_reads,
    Deletion_Percentage = round(deletion_percentage, 2),
    Deletion_Reads = deletion_reads,
    Indel_Percentage = round(indel, 2)
  )
  
  # Add the results to the final dataframe
  final_results_indel <- rbind(final_results_indel, result_df_indel)
}

#################################################################################                         
# Read Percentage Analysis  
#################################################################################  

# Initialize a list to store the results
final_results_reads <- data.frame()

# Iterate over all rows of the `dataframe` dataframe to process the results
for (i in 1:nrow(dataframe)) {
  
  # Get the value from the `n` column in row i
  base_name <- dataframe$n[i]
  
  # Create the folder name
  folder <- paste0("CRISPResso_on_", base_name)
  
  # Build the path for the mapping file
  file_mapping <- file.path(folder, "CRISPResso_mapping_statistics.txt")
  
  # Read the file
  mapping_data <- read.delim(file_mapping, sep = "\t", header = TRUE, check.names = FALSE)
  
  # Select the desired columns
  reads_in_inputs <- mapping_data$`READS IN INPUTS`
  reads_aligned <- mapping_data$`READS ALIGNED`
  
  # Calculate the percentage of READS ALIGNED
  percent_reads_aligned <- (reads_aligned / reads_in_inputs) * 100
  
  # Create a dataframe with the results
  result_df_reads <- data.frame(
    Samples = base_name,
    Total_reads = reads_in_inputs,
    Aligned_reads = reads_aligned,
    Aligned_percentage = round(percent_reads_aligned, 2) # Round to 2 decimal places
  )
  
  # Add the results to the final dataframe
  final_results_reads <- rbind(final_results_reads, result_df_reads)
}


#################################################################################
# Create Excel File contend the edition, indel and reads alignment
#################################################################################

# Initialize the final workbook
wb_final <- createWorkbook()

# Read the data from each Excel file (assumed to be preloaded)
dataframe_edition <- final_results_edition
dataframe_indel <- final_results_indel
dataframe_mapping <- final_results_reads
dataframe_edition_total <- final_results_edition_total


# Format decimals for each sheet inline (ensuring 0 is 0.00)
# For the Reads sheet: round the "Aligned_percentage" column to 2 decimals
if ("Aligned_percentage" %in% names(dataframe_mapping)) {
  dataframe_mapping[["Aligned_percentage"]] <- round(dataframe_mapping[["Aligned_percentage"]], 2)
}

# For the Editing sheet: round all numeric columns to 2 decimals
for (col in names(dataframe_edition)) {
  if (is.numeric(dataframe_edition[[col]])) {
    dataframe_edition[[col]] <- round(dataframe_edition[[col]], 2)
  }
}

# For the Indel sheet: reorder columns and round percentage columns to 2 decimals
ordered_columns <- c("Samples", "Insertion_Reads", "Insertion_Percentage", 
                     "Deletion_Reads", "Deletion_Percentage", "Indel_Percentage")
dataframe_indel <- dataframe_indel[, ordered_columns]
if ("Insertion_Percentage" %in% names(dataframe_indel)) {
  dataframe_indel[["Insertion_Percentage"]] <- round(dataframe_indel[["Insertion_Percentage"]], 2)
}
if ("Deletion_Percentage" %in% names(dataframe_indel)) {
  dataframe_indel[["Deletion_Percentage"]] <- round(dataframe_indel[["Deletion_Percentage"]], 2)
}
if ("Indel_Percentage" %in% names(dataframe_indel)) {
  dataframe_indel[["Indel_Percentage"]] <- round(dataframe_indel[["Indel_Percentage"]], 2)
}

# Create common styles
# Header style with top and bottom borders
edge_header_style <- createStyle(
  textDecoration = "bold",
  halign = "center",
  border = c("top", "bottom"),
  borderStyle = "thick"
)

# Centering style for content
centered_style <- createStyle(halign = "center")

# Create a style for two-decimal number formatting
two_decimal_style <- createStyle(numFmt = "0.00")

# Create Sheets and Write Data
# Reads Sheet
addWorksheet(wb_final, "Reads")
writeData(wb_final, "Reads", dataframe_mapping)
addStyle(wb_final, sheet = "Reads", style = edge_header_style, 
         rows = 1, cols = 1:ncol(dataframe_mapping), gridExpand = TRUE)
addStyle(wb_final, sheet = "Reads", style = centered_style, 
         rows = 2:(nrow(dataframe_mapping) + 1), cols = 1:ncol(dataframe_mapping), gridExpand = TRUE)
setColWidths(wb_final, sheet = "Reads", cols = 1:ncol(dataframe_mapping), widths = "auto")

# Apply two-decimal formatting to the "Aligned_percentage" column in Reads
aligned_percent_col <- which(names(dataframe_mapping) == "Aligned_percentage")
if (length(aligned_percent_col) > 0) {
  addStyle(wb_final, sheet = "Reads", style = two_decimal_style,
           rows = 2:(nrow(dataframe_mapping)+1), cols = aligned_percent_col,
           gridExpand = TRUE, stack = TRUE)
}

# Editing Sheet
addWorksheet(wb_final, "Editing")
writeData(wb_final, "Editing", dataframe_edition)
addStyle(wb_final, sheet = "Editing", style = edge_header_style, 
         rows = 1, cols = 1:ncol(dataframe_edition), gridExpand = TRUE)
addStyle(wb_final, sheet = "Editing", style = centered_style, 
         rows = 2:(nrow(dataframe_edition) + 1), cols = 1:ncol(dataframe_edition), gridExpand = TRUE)
setColWidths(wb_final, sheet = "Editing", cols = 1, widths = "auto")  # Adjust only the first column

# Apply two-decimal formatting to all numeric columns in Editing
numeric_cols_editing <- which(sapply(dataframe_edition, is.numeric))
if (length(numeric_cols_editing) > 0) {
  addStyle(wb_final, sheet = "Editing", style = two_decimal_style,
           rows = 2:(nrow(dataframe_edition)+1), cols = numeric_cols_editing,
           gridExpand = TRUE, stack = TRUE)
}

# Indel Sheet
addWorksheet(wb_final, "Indel")
writeData(wb_final, "Indel", dataframe_indel)
addStyle(wb_final, sheet = "Indel", style = edge_header_style, 
         rows = 1, cols = 1:ncol(dataframe_indel), gridExpand = TRUE)
addStyle(wb_final, sheet = "Indel", style = centered_style, 
         rows = 2:(nrow(dataframe_indel) + 1), cols = 1:ncol(dataframe_indel), gridExpand = TRUE)
setColWidths(wb_final, sheet = "Indel", cols = 1:ncol(dataframe_indel), widths = "auto")

# Apply two-decimal formatting to percentage columns in Indel
percentage_cols_indel <- which(names(dataframe_indel) %in% c("Insertion_Percentage", "Deletion_Percentage", "Indel_Percentage"))
if (length(percentage_cols_indel) > 0) {
  addStyle(wb_final, sheet = "Indel", style = two_decimal_style,
           rows = 2:(nrow(dataframe_indel)+1), cols = percentage_cols_indel,
           gridExpand = TRUE, stack = TRUE)
}

# Total Editing Sheet
addWorksheet(wb_final, "Total Editing")
writeData(wb_final, "Total Editing", dataframe_edition_total)
addStyle(wb_final, sheet = "Total Editing", style = edge_header_style, 
         rows = 1, cols = 1:ncol(dataframe_edition_total), gridExpand = TRUE)
addStyle(wb_final, sheet = "Total Editing", style = centered_style, 
         rows = 2:(nrow(dataframe_edition_total) + 1), cols = 1:ncol(dataframe_edition_total), gridExpand = TRUE)
setColWidths(wb_final, sheet = "Total Editing", cols = 1, widths = "auto")  # Adjust only the first column

# Conditional Formatting in the Reads Sheet
# Create styles for conditional formatting
light_green_style <- createStyle(fgFill = "#D3F9D8")  # Light green
light_red_style <- createStyle(fgFill = "#FFCCCC")    # Light red
light_NC_style <- createStyle(fgFill = "#FFFFCC") # Light Yellow

# Identify the columns "Total_reads", "Aligned_reads", and "Aligned_percentage"
col_total_reads <- which(names(dataframe_mapping) == "Total_reads")
col_reads_algn <- which(names(dataframe_mapping) == "Aligned_reads")
col_perct_algnt <- which(names(dataframe_mapping) == "Aligned_percentage")

# For "Total_reads": if > 10000 then light green
rows_green_total <- which(dataframe_mapping[[col_total_reads]] > 10000) + 1  # +1 for header
addStyle(wb_final, sheet = "Reads", style = light_green_style, 
         rows = rows_green_total, cols = col_total_reads, gridExpand = TRUE)

# For "Total_reads": if < 10000 then light red
rows_red_total <- which(dataframe_mapping[[col_total_reads]] < 10000) + 1
addStyle(wb_final, sheet = "Reads", style = light_red_style, 
         rows = rows_red_total, cols = col_total_reads, gridExpand = TRUE)

# For "Aligned_reads": if < 10000 then light red
rows_red_aligned <- which(dataframe_mapping[[col_reads_algn]] < 10000) + 1
addStyle(wb_final, sheet = "Reads", style = light_red_style, 
         rows = rows_red_aligned, cols = col_reads_algn, gridExpand = TRUE)

# For "Aligned_percentage": values between 50 and 100 (light green)
rows_green_percent <- which(dataframe_mapping[[col_perct_algnt]] >= 50 & dataframe_mapping[[col_perct_algnt]] <= 100) + 1
addStyle(wb_final, sheet = "Reads", style = light_green_style, 
         rows = rows_green_percent, cols = col_perct_algnt, gridExpand = TRUE)

# For "Aligned_percentage": values between 30 and 50 (Light Yellow)
rows_NC_percent <- which(dataframe_mapping[[col_perct_algnt]] >= 30 & dataframe_mapping[[col_perct_algnt]] < 50) + 1
addStyle(wb_final, sheet = "Reads", style = light_NC_style, 
         rows = rows_NC_percent, cols = col_perct_algnt, gridExpand = TRUE)

# For "Aligned_percentage": values less than 30 (light red)
rows_red_percent <- which(dataframe_mapping[[col_perct_algnt]] < 30) + 1
addStyle(wb_final, sheet = "Reads", style = light_red_style, 
         rows = rows_red_percent, cols = col_perct_algnt, gridExpand = TRUE)

# Create the Legend for Conditional Formatting in the Reads Sheet

legend_data <- data.frame(
  Color = c("Light Green", "Light Yellow", "Light Red"),
  Meaning = c(
    "Total reads > 10000 or Alignment percentage >= 50%",
    "Alignment percentage between 30% and 50%",
    "Alignment percentage < 30%, or Total/Aligned reads < 10000"
  )
)

# Define the position for the legend (column after the data + one space)
legend_col <- ncol(dataframe_mapping) + 2
legend_row_start <- 2

# Create a bold style for the legend title
bold_title_style <- createStyle(textDecoration = "bold")

# Write the legend title and data
writeData(wb_final, sheet = "Reads", x = "Color Legend", 
          startCol = legend_col, startRow = legend_row_start - 1)
addStyle(wb_final, sheet = "Reads", style = bold_title_style, 
         rows = legend_row_start - 1, cols = legend_col)
writeData(wb_final, sheet = "Reads", x = legend_data, 
          startCol = legend_col, startRow = legend_row_start, 
          colNames = FALSE, rowNames = FALSE)

# Apply style vectorized based on legend "Color" values
addStyle(wb_final, sheet = "Reads", style = light_green_style, 
         rows = legend_row_start + which(legend_data$Color == "Light Green") - 1, 
         cols = legend_col, gridExpand = TRUE)
addStyle(wb_final, sheet = "Reads", style = light_NC_style, 
         rows = legend_row_start + which(legend_data$Color == "Light Yellow") - 1, 
         cols = legend_col, gridExpand = TRUE)
addStyle(wb_final, sheet = "Reads", style = light_red_style, 
         rows = legend_row_start + which(legend_data$Color == "Light Red") - 1, 
         cols = legend_col, gridExpand = TRUE)

# Adjust the width of the legend column
setColWidths(wb_final, sheet = "Reads", cols = legend_col, widths = 20)

# Save the Final Excel File
# Define the final file name and path (assuming variable 'file' is defined)
name_file_final <- paste0(sub("\\.txt$", "", basename(file)), "_final_result.xlsx")
pth_file_final <- file.path(dirname(file), "../Final_result", name_file_final)

# Save the workbook
saveWorkbook(wb_final, file = pth_file_final, overwrite = TRUE)

# Inform the user that the file has been generated
cat("Final Excel file generated: ", pth_file_final, "\n")

# Return to the initial directory after processing
setwd("..")
}


#################################################################################
# Compiled Individual Reads for each sample from Crispresso2 outputs
#################################################################################

# Get the list of TXT files in the current folder
files_txt <- list.files(pattern = "\\.txt$")

# Loop through each TXT file to process the read images
for (file_txt in files_txt) {
  
  # Extract the base name of the file (removing the .txt extension)
  base_name <- sub("\\.txt$", "", file_txt)
  
  # Define the new subfolder inside 'Final_result' with the suffix '_compiled_reads'
  subfolder_cmpls <- file.path("Final_result", paste0(base_name, "_compiled_reads"))
  dir.create(subfolder_cmpls, showWarnings = FALSE, recursive = TRUE)
  
  # Read the data from the TXT file
  dataframe <- read.delim(file_txt, sep = "\t", header = TRUE)
  
  # Define the main folder where the CRISPResso results are located
  main_folder <- paste0("CRISPRessoBatch_on_", base_name)
  
  # Iterate through each row of the 'dataframe' dataframe to process the images
  for (i in 1:nrow(dataframe)) {
    
    # Get the values from the 'n', 'an' and 'gn' columns for the current sample
    n_base <- dataframe$n[i]
    an_base <- dataframe$an[i]
    gn_base <- dataframe$gn[i]
    
    # Construct the path to the PNG image within the corresponding subfolder
    subfolder <- file.path(main_folder, paste0("CRISPResso_on_", n_base))
    name_file_png <- paste0("9.", an_base, ".Alleles_frequency_table_around_", gn_base, ".png")
    file_png <- file.path(subfolder, name_file_png)
    
    # Check if the PNG file exists before proceeding
    if (file.exists(file_png)) {
      # Define the new name for the image: the sample name followed by .png
      nwe_name <- paste0(n_base, ".png")
      
      # Define the full output path in the subfolder inside 'Final_result'
      output_png <- file.path(subfolder_cmpls, nwe_name)
      
      # Copy the image to the destination, overwriting if it already exists
      file.copy(from = file_png, to = output_png, overwrite = TRUE)
      
      cat("Image transferred to:", output_png, "\n")
    } else {
      warning(paste("PNG file not found:", file_png))
    }
  }
}


#################################################################################
# General heatmaps for each Batch files
#################################################################################

# Get the list of TXT files in the current folder
files_txt <- list.files(pattern = "\\.txt$")

for (file_txt in files_txt) {
  # Extract the base name (without extension)
  base_name <- sub("\\.txt$", "", file_txt)
  
  # Read the TXT file to get the order of the samples (now using the 'n' column)
  txt_data <- read.delim(file_txt, sep = "\t", header = TRUE)
  
  # Check if the "n" column exists
  if (!"n" %in% names(txt_data)) {
    stop(paste("The 'n' column was not found in the file", file_txt))
  }
  
  # The order of the samples will be as in the TXT file (column 'n')
  odm_smps_txt <- txt_data$n
  
  # Define the expected name of the corresponding Excel file
  file_excel <- paste0(base_name, "_final_result.xlsx")
  
  # Check if the Excel file exists in the "Final_result" folder
  if (file.exists(file.path("Final_result", file_excel))) {
    
    # Read the "Total Editing" and "Indel" sheets
    final_results_edition_total <- read_excel(file.path("Final_result", file_excel), sheet = "Total Editing")
    dataframe_indel <- read_excel(file.path("Final_result", file_excel), sheet = "Indel")
    
    # Adjust the Indel data
    dataframe_indel <- dataframe_indel %>% 
      select(Samples, Indel_Percentage) %>% 
      mutate(Indel_Percentage = round(Indel_Percentage, 2))
    
    # Convert the "Total Editing" data to long format
    data_long <- pivot_longer(final_results_edition_total, 
                              cols = -Samples, 
                              names_to = "nucleotide", 
                              values_to = "vl")
    data_long$vl <- as.numeric(data_long$vl)
    
    # Define the factor order for Samples using the TXT order
    # We use rev() so that the first row of the TXT (first sample) is at the top
    data_long$Samples <- factor(data_long$Samples, levels = rev(odm_smps_txt))
    dataframe_indel$Samples <- factor(dataframe_indel$Samples, levels = rev(odm_smps_txt))
    
    # Define the order of the nucleotides according to the columns (except "Samples")
    data_long$nucleotide <- factor(data_long$nucleotide,
                                    levels = colnames(final_results_edition_total)[-1])
    
    # Graphical parameters
    hgt_tile <- 0.9
    y_lower <- 1 - hgt_tile/2      # Bottom edge of the tile
    dash_length <- 0.1            # Length of the line
    edge_lower <- y_lower       
    
    # Maximum values for the scale
    max_vl <- max(final_results_edition_total[,-1], na.rm = TRUE)
    max_vl_rounded <- ceiling(max_vl/10)*10
    vl_maxm_60 <- 0.80 * max_vl_rounded
    
    # Create sample groups: maximum 10 samples per group,but if the last group has fewer than 2 samples, merge it with the previous group
    group_size <- 12
    groups <- split(odm_smps_txt, ceiling(seq_along(odm_smps_txt) / group_size))
    if (length(groups) > 1 && length(groups[[length(groups)]]) < 2) {
      groups[[length(groups)-1]] <- c(groups[[length(groups)-1]], groups[[length(groups)]])
      groups <- groups[-length(groups)]
    }
    
    group_index <- 1
    for (group in groups) {
      # Filter the data for the samples in this group
      data_long_grp <- data_long %>% filter(Samples %in% group)
      dataframe_indel_grp <- dataframe_indel %>% filter(Samples %in% group)
      
      # Adjust the factor order for this group (reverse so the first sample is at the top)
      data_long_grp$Samples <- factor(data_long_grp$Samples, levels = rev(group))
      dataframe_indel_grp$Samples <- factor(dataframe_indel_grp$Samples, levels = rev(group))
      
      heatmap <- ggplot(data_long_grp, aes(x = nucleotide, y = Samples, fill = vl)) +
        geom_tile(color = "#000000", size = 0.1, height = hgt_tile) +
        scale_fill_gradientn(
          colors = c("white", "#f4f9fc", "#c5d2e9", "#97b2d8", "#6a92c7", "#3e6bb6", "#2e3868"),
          na.value = "#e0e0e0",
          limits = c(0, max_vl_rounded),
          breaks = seq(0, max_vl_rounded, length.out = 4),
          labels = formatC(seq(0, max_vl_rounded, length.out = 4), format = "f", digits = 0)
        ) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(angle = 0, color = "black", hjust = 0.5, vjust = 1, size = 10),
          axis.text.y = element_text(size = 10, color = "black"),
          axis.title = element_blank(),
          panel.grid = element_blank(),
          legend.position = "right",
          legend.box.margin = margin(l = 60)
        ) +
        scale_x_discrete(expand = c(0,0),
                         labels = function(labels) {
                           sapply(labels, function(lbl) {
                             gsub("([A-Z])([0-9]+)", "\\1<sub>\\2</sub>", lbl)
                           })
                         }) +
        guides(fill = guide_colorbar(
          title = "A-to-G (%)",
          barwidth = 1,
          barheight = 12,
          frame.colour = "black",
          frame.linewidth = 0.5,
          ticks = TRUE,
          ticks.colour = "black",
          ticks.linewidth = 1.0,
          draw.ulim = FALSE,
          draw.llim = FALSE
        )) +
        geom_segment(aes(x = as.numeric(nucleotide), xend = as.numeric(nucleotide),
                         y = y_lower, yend = y_lower - dash_length),
                     color = "black", size = 0.25) +
        geom_text(aes(label = ifelse(!is.na(vl) & vl >= 1, 
                                     formatC(vl, format = "f", digits = 1), "")),
                  fontface = "bold",
                  color = ifelse(data_long_grp$vl > vl_maxm_60, "white", "black"),
                  size = 3.5,
                  angle = 90) +
        ggtitle(paste0(base_name, "_", group_index)) +
        theme(
          plot.title = element_text(hjust = 0, vjust = -3, size = 12, face = "bold"),
          plot.margin = margin(t = 3, r = 10, b = 10, l = 10),
          axis.text.x = element_markdown(size = 10)
        )
      
      max_x <- length(levels(data_long_grp$nucleotide))
      heatmap <- heatmap +
        geom_text(
  data = dataframe_indel_grp,
  inherit.aes = FALSE,
  aes(x = max_x + 0.7, y = Samples, label = paste("Indel:", formatC(Indel_Percentage, format = "f", digits = 2))),
  hjust = 0, vjust = 0.5, size = 3.5
) +
        coord_cartesian(clip = "off", xlim = c(NA, max_x + 1))
      
      n_smps_grp <- length(group)
      height_dynamic <- max(3, min(n_smps_grp, 20))
      
      name_file_tiff <- paste0(base_name, "_final_result_", group_index, ".tiff")
      pth_file_tiff <- file.path("Final_result", name_file_tiff)
      
      tiff(pth_file_tiff, width = 11, height = height_dynamic, units = "in", res = 400)
      print(heatmap)
      dev.off()
      
      cat("Saved:", pth_file_tiff, "\n")
      
      group_index <- group_index + 1
    }
    
  } else {
    cat("Excel file not found for:", file_txt, "\n")
  }
}


#################################################################################      
#Individual Heatmaps
#################################################################################

# Get the list of TXT files in the current folder
files_txt <- list.files(pattern = "\\.txt$")

# Loop through each TXT file to find the corresponding Excel files
for (file_txt in files_txt) {
  base_name <- sub("\\.txt$", "", file_txt)
  file_excel <- paste0(base_name, "_final_result.xlsx")
  
  if (file.exists(file.path("Final_result", file_excel))) {
    final_results_edition_total <- read_excel(file.path("Final_result", file_excel), sheet = "Total Editing")
    dataframe_indel <- read_excel(file.path("Final_result", file_excel), sheet = "Indel")
    
    dataframe_indel <- dataframe_indel %>% 
      select(Samples, Indel_Percentage) %>% 
      mutate(Indel_Percentage = round(Indel_Percentage, 2))
    
    data_long <- pivot_longer(final_results_edition_total, cols = -Samples, 
                              names_to = "nucleotide", values_to = "vl")
    data_long$vl <- as.numeric(data_long$vl)
    
    data_long$nucleotide <- factor(data_long$nucleotide, 
                                    levels = colnames(final_results_edition_total)[-1])
    
    max_vl <- max(final_results_edition_total[, -1], na.rm = TRUE)
    max_vl_rounded <- ceiling(max_vl / 10) * 10
    vl_maxm_60 <- 0.80 * max_vl_rounded
    
    smps_unqs <- unique(data_long$Samples)
    
    # Define the new subfolder inside 'Final_result' with the suffix '_compiled_heatmaps'
    subfolder_cmpls <- file.path("Final_result", paste0(base_name, "_compiled_heatmaps"))
    dir.create(subfolder_cmpls, showWarnings = FALSE, recursive = TRUE)
    
    for (smp in smps_unqs) {
      data_smp <- filter(data_long, Samples == smp)
      indel_vl <- dataframe_indel$Indel_Percentage[dataframe_indel$Samples == smp]
      data_smp <- data_smp %>% mutate(post = 1)
      
      hgt_tile <- 0.9
      y_lower <- 1 - hgt_tile/2
      dash_length <- 0.1
      edge_lower <- y_lower
      
      num_nucleotides <- length(levels(data_smp$nucleotide))
      
      heatmap <- ggplot(data_smp, aes(x = nucleotide, y = post, fill = vl)) +
        geom_tile(color = NA, size = 0.1, height = hgt_tile) +
        scale_fill_gradientn(
          colors = c("white", "#f4f9fc", "#c5d2e9", "#97b2d8", "#6a92c7", "#3e6bb6", "#2e3868"), 
          na.value = "#e0e0e0", 
          limits = c(0, max_vl_rounded),
          breaks = seq(0, max_vl_rounded, length.out = 4),
          labels = formatC(seq(0, max_vl_rounded, length.out = 4), format = "f", digits = 0)
        ) +
        geom_segment(aes(x = as.numeric(nucleotide), xend = as.numeric(nucleotide),
                         y = y_lower, yend = y_lower - dash_length),
                     color = "black", size = 0.4) +
        geom_text(aes(
            label = ifelse(!is.na(vl) & vl >= 1, formatC(vl, format = "f", digits = 1), "")
          ),
          fontface = "bold",
          color = ifelse(data_smp$vl > vl_maxm_60, "white", "black"),
          size = 2.8, angle = 90) +
        theme_minimal() +
        theme(
          axis.text.x = element_markdown(size = 9, color = "black"),
          axis.text.y = element_blank(),
          axis.title = element_blank(),
          panel.grid = element_blank(),
          legend.position = "right"
        ) +
        scale_x_discrete(
          expand = c(0, 0),
          labels = function(labels) {
            sapply(labels, function(lbl) {
              gsub("([A-Z])(\\d+)", "\\1<sub>\\2</sub>", lbl)
            })
          }
        ) +
        guides(fill = guide_colorbar(
          title = "A-to-G (%)",
          barwidth = 1,
          barheight = 5,
          frame.colour = "black",
          frame.linewidth = 0.5,
          ticks = TRUE,
          ticks.colour = "black",
          ticks.linewidth = 1.0,
          draw.ulim = FALSE,
          draw.llim = FALSE
        )) +
        geom_rect(xmin = 0.5, xmax = num_nucleotides + 0.5, 
                  ymin = edge_lower, ymax = 1 + hgt_tile/2,
                  color = "black", fill = NA, size = 0.5, inherit.aes = FALSE) +
        ggtitle(paste(smp)) +
        annotate("text", x = Inf, y = Inf, 
         label = paste("Indel:", formatC(indel_vl, format = "f", digits = 2)),
         hjust = 1.1, vjust = -0.1, size = 3) +
        coord_cartesian(ylim = c(edge_lower, 1 + hgt_tile/2), clip = "off")
      
      name_file_tiff <- paste0(base_name, "_", smp, ".tiff")
      pth_file_tiff <- file.path(subfolder_cmpls, name_file_tiff)
      
      tiff(pth_file_tiff, width = 8, height = 1.5, units = "in", res = 400)
      print(heatmap)
      dev.off()
      
      cat("Saved:", pth_file_tiff, "\n")
    }
  }
}



#################################################################################     
#Analysis of indels >0.2%
#################################################################################

# Create the folder for the final results, if it doesn't exist yet
if (!dir.exists("Final_result")) {
  dir.create("Final_result")
}

# Load all .txt files in the current directory
files_txt <- list.files(pattern = "\\.txt$", full.names = TRUE)

# Loop to process each .txt file
for (file in files_txt) {
  
  cat("Processing file:", file, "\n")
  
  # Read the main file
  dataframe <- read.delim(file, sep = "\t", header = TRUE)
  
  # Remove the file extension to use it in the folder and Excel file names
  base_name_file <- tools::file_path_sans_ext(basename(file))
  
  # Create a specific folder for this file (optional, if needed for organization)
  folder_file <- paste0("CRISPRessoBatch_on_", base_name_file)
  if (!dir.exists(folder_file)) {
    dir.create(folder_file)
  }
  
  # Change to the created folder (optional, depending on organization)
  setwd(folder_file)
  
  # List to store the data frames of each sample (each will come as a sheet in the Excel file)
  lst_smps <- list()
  
  # Loop to process each sample (each row of the main file)
  for (i in 1:nrow(dataframe)) {
    
    # Get the values from the columns n, an, and gn for the current sample
    base_name_smp <- dataframe$n[i]
    an_base <- dataframe$an[i]
    gn_base <- dataframe$gn[i]
    
    # Build the sample file name based on the columns an and gn
    name_file_smp <- paste0(an_base, ".Alleles_frequency_table_around_", gn_base, ".txt")
    
    # Build the full path of the sample file
    folder_smp <- paste0("CRISPResso_on_", base_name_smp)
    pth_file_smp <- file.path(folder_smp, name_file_smp)
    
    # Read the sample .txt file (keeping the original column names)
    data <- read.table(pth_file_smp, header = TRUE, sep = "\t", 
                       check.names = FALSE, row.names = NULL, comment.char = "")
    
    # Remove the unwanted columns
    data <- subset(data, select = -c(Unedited, n_mutated))
    
    # Create the "sma" column as the sum of n_deleted and n_inserted values
    data$sma <- data$n_deleted + data$n_inserted
    
    # Remove the rows where "sma" is equal to 0
    data <- subset(data, sma != 0)
    
    # Delete the "sma" column
    data <- subset(data, select = -sma)
    
    # Filter: remove the rows where the "%Reads" column is less than 0.2
    data_filter <- data[data$`%Reads` >= 0.2, ]
    
    # Add the filtered data frame to the list only if there are rows
    if (nrow(data_filter) > 0) {
      lst_smps[[base_name_smp]] <- data_filter
    } else {
      cat("Sample", base_name_smp, "was excluded because it has no rows after filtering.\n")
    }
  }
  
  # If there is at least one valid sample, create the Excel file
  if (length(lst_smps) > 0) {
    # Create a new workbook
    wb <- createWorkbook()
    
    # Define the style for the header: bold with a bottom border
    hder_style <- createStyle(textDecoration = "bold", 
                                   border = "bottom", 
                                   borderStyle = "thin")
    
    # For each sample (each element in the list), create a sheet
    for (sheetName in names(lst_smps)) {
      addWorksheet(wb, sheetName)
      
      # Write the data to the sheet with the header style applied
      writeData(wb, sheet = sheetName, lst_smps[[sheetName]], headerStyle = hder_style)
      
      # Expand the columns to fit the content size
      setColWidths(wb, sheet = sheetName, 
                   cols = 1:ncol(lst_smps[[sheetName]]), widths = "auto")
    }
    
    # Excel file name to be saved (e.g., "file_indels.xlsx")
    name_excel <- paste0(base_name_file, "_indels.xlsx")
    
    # Save the Excel file in the "Final_result" folder
    saveWorkbook(wb, file = file.path("..", "Final_result", name_excel), overwrite = TRUE)
    
    cat("Excel file saved as:", file.path("Final_result", name_excel), "\n")
  } else {
    cat("No valid samples for the file", base_name_file, "- Excel was not created.\n")
  }
  
  # Go back to the previous directory to process the next file
  setwd("..")
}



#################################################################################       
#Organization of outputs
#################################################################################


# Define the "Final_result" directory where the files are located
drct_result <- file.path(dirname(file), "Final_result")

# List all Excel files within the "Final_result" folder that contain "Final_result" in the name
files_excel <- list.files(drct_result, pattern = "final_result.*\\.xlsx$", full.names = TRUE)

# Name of the sheet to be removed
name_sheet <- "Total Editing"

# Loop through all the found files
for (pth_file in files_excel) {
  # Check if the sheet exists using openxlsx
  wb <- loadWorkbook(pth_file)
  sheets <- names(wb)
  
  if (name_sheet %in% sheets) {
    removeWorksheet(wb, name_sheet)
    
    # Save the file again within the same directory
    saveWorkbook(wb, pth_file, overwrite = TRUE)
    cat("The sheet '", name_sheet, "' was successfully removed from the file:", pth_file, "\n")
  } else {
    cat("The sheet '", name_sheet, "' was not found in the file:", pth_file, "\n")
  }
}

# Clean up the names (removing "./" and ".txt") and trim any whitespace
files_txt_clean <- trimws(gsub("^\\./|\\.txt$", "", files_txt))

# Sort the base names in descending order (longer names first)
files_txt_clean <- files_txt_clean[order(nchar(files_txt_clean), decreasing = TRUE)]
cat("Base names (sorted):\n")
print(files_txt_clean)

# Define the directory where the files to be organized are located
drct_result <- file.path(dirname(file), "Final_result")

# List the files present in the folder (only the names, without the full path)
files_result <- list.files(drct_result)
cat("Files found in 'Final_result':\n")
print(files_result)
cat("\n")

# For each base name, find and move the files that start exactly with it
for (base_name in files_txt_clean) {
  
    pattern <- paste0("^", base_name, "($|[_\\.])")
  
  # Filter the files that match the pattern
  files_corresponding <- files_result[grepl(pattern, files_result)]
  
  if (length(files_corresponding) > 0) {
    # Create the destination folder (inside "Final_result") with the base name
    nva_folder <- file.path(drct_result, base_name)
    if (!dir.exists(nva_folder)) {
      dir.create(nva_folder, recursive = TRUE)
      cat("Created the folder:", nva_folder, "\n")
    }
    
    # Move each matching file to the new folder
    for (arq in files_corresponding) {
      orgm <- file.path(drct_result, arq)
      dstn <- file.path(nva_folder, arq)
      cat("Trying to move:\n  Source: ", orgm, "\n  Destination:", dstn, "\n")
      if (file.rename(orgm, dstn)) {
        cat("  >> File", arq, "successfully moved to", nva_folder, "\n")
      } else {
        cat("  >> Failed to move the file:", arq, "\n")
      }
      # Remove the moved file from the list so it is not processed again
      files_result <- setdiff(files_result, arq)
    }
  } else {
    cat("No matching files found for:", base_name, "\n")
  }
  
  cat("\n")
}
###################################################################################
#Save the instructions (Read me File)
###################################################################################

# Define the description text
description <- paste(
  "###################################################################################",
  "Instructions",
  "###################################################################################",
  "",
  "Thank you for using Fast Analyzr BE!",
  "",
  "All results are stored in the Final_result folder, including this file with post-analysis instructions. For each Batch file, a separate folder will be created. Inside these folders, you will find the compiled_reads and compiled_heatmaps directories, as well as the final_result.xlsx and final_result.tiff files. Additionally, the indels.xlsx file may be generated in certain cases, as described at the end of this document.",
  "",
  "In the compiled_reads folder, you will find a file for each sample displaying the Allele plot obtained using Crispresso2. The compiled_heatmaps folder contains a heatmap representing gene editing, along with the indel values for each sample individually.",
  "",
  "The final_result.xlsx file consists of three sheets:",
  "1. Reads: Contains data for each sample. A legend is provided, and columns are color-coded based on the legend's criteria. The following three columns are included:",
  "   - Total_reads",
  "   - Aligned_reads",
  "   - Aligned_percentage",
  "",
  "2. Editing: Displays editing data in percentage (A-to-G for ABE and C-to-T for CBE). Only A or C nucleotides and their positions within the gRNA are represented.",
  "",
  "3. Indel: Contains indel values, represented by the following columns:",
  "   - Insertion_Reads",
  "   - Insertion_Percentage",
  "   - Deletion_Reads",
  "   - Deletion_Percentage",
  "   - Indel_Percentage",
  "",
  "The final_result.tiff file is a heatmap plot displaying editing rates and indel values for each sample. If the number of samples exceed 12, multiple heatmaps will be generated.",
  "",
  "Finally, the indels.xlsx file will be generated if any sample exhibits an indel frequency higher than 0.2%. Samples meeting this criterion will be placed in separate sheets within the file.",
  "",
  "Any deviation from the expected outputs described above may indicate an error in script execution. Please carefully review these instructions.",
  "",
  "Enjoy analyzing your results!",
  sep="\n"
)

# Define the output file path
output_file <- "Final_result/Instructions.txt"

# Save the text to the file
writeLines(description, output_file)

cat("Instructions saved to", output_file, "\n")
```
EOF

# Declare associative arrays to store unique guide IDs for normal/inverted classification,
# and a mapping for each guide to its base editing type (ABE or CBE)
declare -A normal_matrix
declare -A inverted_matrix
declare -A be_mapping

# Define required columns for HTML
required_columns=("fastq_r1" "fastq_r2" "a" "an" "g" "gn" "n" "DNA_F_or_R" "BE")

# Loop through .txt files and extract necessary information
for file in *.txt; do
    if [[ -f "$file" ]]; then
        # Find the column indices for required columns
        read -r header < "$file"
        IFS=$'\t' read -ra columns <<< "$header"
        
        declare -A col_idx
        for i in "${!columns[@]}"; do
            for col in "${required_columns[@]}"; do
                if [[ "${columns[i]}" == "$col" ]]; then
                    col_idx[$col]=$((i+1))
                fi
            done
        done
        
        # Read file content, skipping header
        while IFS=$'\t' read -r -a line; do
            # Ensure the indices are valid before accessing
            gn_value="${line[col_idx[gn]-1]}"
            strand_value="${line[col_idx[DNA_F_or_R]-1]}"
            be_value_line="${line[col_idx[BE]-1]}"
            
            # Classify guides based on DNA_F_or_R and store the guide's association with its BE
            if [[ "$strand_value" == "F" ]]; then
                normal_matrix["$gn_value"]=1
                if [[ "$be_value_line" == "ABE" || "$be_value_line" == "CBE" ]]; then
                    be_mapping["$gn_value"]="$be_value_line"
                fi
            elif [[ "$strand_value" == "R" ]]; then
                inverted_matrix["$gn_value"]=1
                if [[ "$be_value_line" == "ABE" || "$be_value_line" == "CBE" ]]; then
                    be_mapping["$gn_value"]="$be_value_line"
                fi
            fi
        done < <(tail -n +2 "$file")
    fi
done

# Check for mutual exclusivity between normal_matrix and inverted_matrix
for normal_guide in "${!normal_matrix[@]}"; do
    if [[ -n "${inverted_matrix[$normal_guide]}" ]]; then
        echo -e "${RED}Error: Guide ID '${normal_guide}' found in both 'normal_matrix' and 'inverted_matrix'. A guide cannot be classified as both 'F' and 'R'. Please check your input data.${NC}"
        exit 1
    fi
done

# End of mutual exclusivity check
# Convert arrays to formatted R vectors, handling empty cases

# normal_matrix vector
if [[ ${#normal_matrix[@]} -eq 0 ]]; then
    normal_matrix_input_quoted='c("")'
else
    normal_vector=$(printf '"%s", ' "${!normal_matrix[@]}")
    normal_vector=${normal_vector%, }    # Remove trailing comma and space
    normal_matrix_input_quoted="c($normal_vector)"
fi

# inverted_matrix vector
if [[ ${#inverted_matrix[@]} -eq 0 ]]; then
    inverted_matrix_input_quoted='c("")'
else
    inverted_vector=$(printf '"%s", ' "${!inverted_matrix[@]}")
    inverted_vector=${inverted_vector%, }    # Remove trailing comma and space
    inverted_matrix_input_quoted="c($inverted_vector)"
fi

# Convert BE mapping to a named vector in R, in the format "guide"="BE"
if [[ ${#be_mapping[@]} -eq 0 ]]; then
    be_vector='c()'
else
    be_vector=""
    for key in "${!be_mapping[@]}"; do
        be_vector+=$(printf '"%s"="%s", ' "$key" "${be_mapping[$key]}")
    done
    be_vector=${be_vector%, }    # Remove trailing comma and space
    be_vector="c($be_vector)"
fi

# Execute the R script, passing the formatted parameters
R -e "knitr::opts_knit\$set(root.dir = '$current_dir'); rmarkdown::render('$current_dir/temp_script.Rmd', params=list(normal_matrix=$normal_matrix_input_quoted, inverted_matrix=$inverted_matrix_input_quoted, base_editing=$be_vector), quiet=TRUE)"

# Capture the exit code IMMEDIATELY after the R execution
R_EXIT_CODE=$?

# Clean up by removing the temporary Rmd file and HTML file (do not overwrite the exit code)
rm "$current_dir/temp_script.Rmd"
rm "$current_dir/html_file.html"

# Check the exit code of the R command
if [ $R_EXIT_CODE -eq 0 ]; then
    display_footer
    echo ""
    echo -e "${NC}Analysis completed!${NC}"
    echo ""
else
    echo ""
    echo ""
    echo -e "${RED}Analysis failed.${NC}"
    echo ""
fi