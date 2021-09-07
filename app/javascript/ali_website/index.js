(function($){
  $(function(){
    var table = $(".js-order-table").DataTable({
      paging: false,
      columnDefs: [
        {
          targets: "js-no-sort",
          orderable: false
        }, {
          targets: "js-numeric-sort",
          data: function ( row, type, val, meta ) {
            if (type === 'set') {
              row.price = val.replace(/[^0-9\.]/g, "");
              row.price_display = val;
              // Store the computed display and filter values for efficiency
              return;
            }
            else if (type !== 'display') {
              return Number(row.price);
            }
            return row.price_display;
          }
        }
      ]
    });
    window.table = table;

    $(".js-order-filter-buttons input[type=button]").on('click', function(e) {
      e.preventDefault();
      var currentVal = $(this).data("active");
      var newVal = !currentVal;

      $(".js-order-filter-buttons input[type=button]").
        addClass("btn-secondary").
        removeClass("btn-primary").
        data("active", false);

      if(newVal) {
        $(this).addClass("btn-primary").
          removeClass("btn-secondary")
      }
      $(this).data("active", newVal);

      if(newVal){
        table.column($(this).data("filter-column")).search($(this).data("filter-value"), true).draw();
      } else {
        table.column($(this).data("filter-column")).search("").draw();
      }
    });

    $(".js-item-quantity").popover(
      {
        trigger: "manual",
        placement: "top"
      }
    )

    $(".js-item-quantity").on("focus", function(e) {
      var quantity = Number($(this).val());
      quantity ||= 0;
      stockWarning($(this), quantity, Number($(this).data("stock")));
    });

    $(".js-item-quantity").on("keyup", function(e) {
      var quantity = Number($(this).val());
      quantity ||= 0;
      stockWarning($(this), quantity, Number($(this).data("stock")));

      prices[$(this).data("item")] = Number($(this).data("price")) * quantity;
      calculateTotal();
    });
    calculateTotal(true);

    $(".js-item-quantity").on("blur", function(e) {
      $(this).popover("hide");
    })

    $(".js-order-form").on("keydown", function(e){
      return e.key != "Enter";
    });

    $(".js-order-form").on("submit", function(e){
      resetTableSearch(table);
    });

    $("[data-toggle]").tooltip();

    var clipboard = new ClipboardJS("[data-clipboard-target]");
    $("[data-clipboard-target]").tooltip({title: "Click to Copy"})
    $("[data-clipboard-target]").on("click", function(e){ e.preventDefault(); });
    clipboard.on("success", function (e) {
      $(e.trigger).tooltip("dispose");
      $(e.trigger).tooltip({ title: "Copied!" });
      $(e.trigger).tooltip("enable");
      $(e.trigger).tooltip("show");


      setTimeout(function(){
        $(e.trigger).tooltip("dispose");
        $(e.trigger).tooltip({title: "Click to Copy"})
      }, 1000);
    });

    $(".js-option-contract-fee").on("click", function(e){
      $(".js-contract-fee-table").removeClass("d-none");
      refreshOrderSummary();
    })
    $(".js-option-no-contract-fee").on("click", function(e){
      $(".js-contract-fee-table").addClass("d-none");
      refreshOrderSummary();
    })

    $(".js-review-order").on("show.bs.modal", function(e){
      resetTableSearch(table);

      $(".js-review-order-body").html("");
      $(".js-modal-stock-warning").hide();
      var stockMissing = false;

      $(".js-item-quantity").each(function(){
        var $quantityField = $(this)
        var quantity = Number($quantityField.val());
        if(!quantity || quantity <= 0){
          return true;
        }

        var item = $quantityField.data("item")
        var price = $quantityField.data("price")
        var stock = $quantityField.data("stock")
        var subtotal = quantity * price;

        var inStock = (stock >= quantity);
        stockMissing ||= !inStock;

        var $baseBlueprintCheckbox = $quantityField.closest(".corp_stock").find(".js-blueprint-checkbox");
        var $reviewBlueprintCheckbox = $baseBlueprintCheckbox.clone().show().prop("disabled", false).attr('id', $baseBlueprintCheckbox.attr('id') + '_clone');

        $reviewBlueprintCheckbox.data("quantity", quantity);

        if($baseBlueprintCheckbox.data("force-checked")) {
          $reviewBlueprintCheckbox.
            prop("checked", true).
            prop("disabled", true)
        }

        var displayPrice = (price < 100000 ? formatMoney(price) : formatMoney(price, 0))
        $htmlLine = $(`
          <tr class='js-modal-line'>
            <td>${item}</td>
            <td>${displayPrice}</td>
            <td>${formatMoney(quantity, 0, "")}</td>
            <td>${formatMoney(subtotal, 0)}</td>
            <td>${inStock ? 'Yes' : 'NO'}</td>
          </tr>
        `);
        $htmlLine.data("modal-line-total", subtotal);
        var $line2 = $("");
        if($baseBlueprintCheckbox.length > 0){
          $line2 = $(`
            <tr class='js-modal-line'>
              <td colspan='3' class='js-bp-checkbox-cell'>
                <label for="${$reviewBlueprintCheckbox.attr('id')}">Providing Blueprint?</label>
              </td>
              <td colspan='2' class='js-bp-price-reduction'>

              </td>
            </tr>
          `);
          if($baseBlueprintCheckbox.data("force-checked")) {
            var lineTotal = -$baseBlueprintCheckbox.data("price-reduction") * quantity;
            $line2.find(".js-bp-price-reduction").html(formatMoney(lineTotal, 0));
            $line2.data("modal-line-total", lineTotal);
          } else {
            $line2.data("modal-line-total", 0);
          }
          $line2.find(".js-bp-checkbox-cell").prepend($reviewBlueprintCheckbox);
        }

        $(".js-review-order-body").append($htmlLine).append($line2);
      });

      if(stockMissing){
        $(".js-modal-stock-warning").show();
      }
      refreshOrderSummary();
    });

    $(".js-review-order").on("change", ".js-blueprint-checkbox", function(e){
      var qty = Number($(this).data("quantity"));
      var lineTotal = qty * $(this).data("price-reduction");

      if($(this).prop("checked")) {
        $(this).closest("tr").find(".js-bp-price-reduction").html(formatMoney(-lineTotal, 0));
        $(this).closest("tr").data("modal-line-total", -lineTotal);
      } else {
        $(this).closest("tr").find(".js-bp-price-reduction").html("");
        $(this).closest("tr").data("modal-line-total", 0);
      }

      refreshOrderSummary();
    });

    $(".js-tip").on("change", function(e){
      refreshOrderSummary();
    })
  });
})(jQuery);

function refreshOrderSummary() {
  var total = 0;
  $(".js-modal-line").each(function(){
    var lineTotal = Number($(this).data("modal-line-total"));
    total += lineTotal;
  })
  $(".js-modal-total").html(formatMoney(total, 0));
  tip = Number($(".js-tip").val());

  var contractFee;
  if($(".js-option-contract-fee").prop("checked")) {
    contractFee = total * (0.08 / 0.92);
  } else {
    contractFee = 0;
  }
  $(".js-contract-fee-value").text(formatMoney(contractFee, 0));
  $(".js-modal-tip").text(formatMoney(tip, 0));
  $(".js-contract-fee-final").text(formatMoney(contractFee + total + tip, 0));
}

var prices = {};
function calculateTotal(initiateFields = false) {
  if(initiateFields){
    $(".js-item-quantity").each(function(){
      var quantity = Number($(this).val());
      if (!quantity || quantity <= 0) {
        return true;
      }
      prices[$(this).data("item")] = Number($(this).data("price")) * quantity;
    });
  }

  var total = 0;
  Object.entries(prices).forEach(pricing => {
    const [item, price] = pricing;
    if(price > 0) {
      total += price;
    }
  })

  $(".js-total-price").text(formatMoney(total, 0));
}
window.calculateTotal = calculateTotal;

function formatMoney(amount, decimalCount = 2, unit = "Ƶ", decimal = ".", thousands = ",") {
  try {
    var decimalCount = Math.abs(decimalCount);
    decimalCount = isNaN(decimalCount) ? 2 : decimalCount;

    if (Number(Math.abs(Number(amount) || 0).toFixed(decimalCount)) == Number(Math.abs(Number(amount) || 0).toFixed(0))) {
      decimalCount = 0;
    }

    const negativeSign = amount < 0 ? "-" : "";

    let i = parseInt(amount = Math.abs(Number(amount) || 0).toFixed(decimalCount)).toString();
    // let i = parseInt(amount = Math.abs(Number(amount) || 0)).toString();
    let j = (i.length > 3) ? i.length % 3 : 0;

    return negativeSign + unit + (j ? i.substr(0, j) + thousands : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousands) + (decimalCount ? decimal + Math.abs(amount - i).toFixed(decimalCount).slice(2) : "");
  } catch (e) {
    console.log(e)
  }
};

function resetTableSearch(table) {
  table.search("").columns().search("").draw();

  $(".js-order-filter-buttons input[type=button]").
    addClass("btn-secondary").
    removeClass("btn-primary").
    data("active", false);
}

function stockWarning($input, quantity, stock) {
  if (quantity > stock || stock <= 0) {
    $input.addClass("border-warning").addClass("border-thick");
    $input.popover("show");
  } else {
    $input.removeClass("border-warning").removeClass("border-thick");
    $input.popover("hide");
  }
}
