# Javascript - for editing the datatable with prescribed values.
# Sources: https://stackoverflow.com/questions/52593539/edit-datatable-in-shiny-with-dropdown-selection-for-factor-variables
#          https://stackoverflow.com/questions/60828661/how-to-create-a-dropdown-list-in-a-shiny-table-using-datatable-when-editing-the/60845695#60845695


callback <- c(
  "var tbl = $(table.table().node());",
  "var id = tbl.closest('.datatables').attr('id');",
  "function onUpdate(updatedCell, updatedRow, oldValue) {",
  "  var cellinfo = [{",
  "    row: updatedCell.index().row + 1,",
  "    col: updatedCell.index().column + 1,",
  "    value: updatedCell.data()",
  "  }];",
  "  Shiny.setInputValue(id + '_cell_edit:DT.cellInfo', cellinfo);",
  "}",
  "table.MakeCellsEditable({",
  "  onUpdate: onUpdate,",
  "  inputCss: 'my-input-class',",
  "  confirmationButton: {",
  "    confirmCss: 'my-confirm-class',",
  "    cancelCss: 'my-cancel-class'",
  "  },",
  "  inputTypes: [",
  "    {",
  "      column: 7,",
  "      type: 'list',",
  "      options: [",
  "        {value: 'Keep data', display: 'Keep data'},",
  "        {value: 'Pass', display: 'Pass'},",
  "        {value: 'Delete', display: 'Delete'}",
  "      ]",
  "    }",
  "  ]",
  "});"
)

# callback = htmlwidgets::JS(
#   "function onUpdate(updatedCell, updatedRow, oldValue){}",
#   "table.MakeCellsEditable({",
#   "  onUpdate: onUpdate,",
#   "  inputCss: 'my-input-class',",
#   "  confirmationButton: {",
#   "    confirmCss: 'my-confirm-class',",
#   "    cancelCss: 'my-cancel-class'",
#   "  },",
#   "  inputTypes: [",
#   "    {",
#   "      column: 7,",
#   "      type: 'list',",
#   "      options: [",
#   "        {value: 'Keep data', display: 'Keep data'},",
#   "        {value: 'Pass',      display: 'Pass'},",
#   "        {value: 'Delete',    display: 'Delete'}",
#   "      ]",
#   "    }",
#   "  ]",
#   "});")

#-----------------------------------------------------------------------------------------------------------------------
