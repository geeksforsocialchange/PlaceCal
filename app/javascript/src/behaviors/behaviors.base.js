jQuery.fn.init_behaviors = function () {
    this.find(".behavior-trigger").each(function () {
        var a = jQuery(this).attr("data-behavior");
        if (typeof a == "string") {
            Behaviors.activateBehavior(a.split(","))
        }
    })
};

export const Behaviors = {
  debugMode: true,
  activateBehavior: function (a) {
    if (a && a != "" && a != []) {
      if (typeof a == "string") {
        a = [a]
      }
      jQuery.each(a, function () {
          var a = this;
          if (Behaviors.debugMode) {
            window.console && window.console.log("# initializing '" + a + "' behavior")
          }
          var b = a.split(".");
          var c = Behaviors;
          jQuery.each(b, function () {
            if (c && c[this]) {
                c = c[this]
            }
          });
          if (c["init"]) {
            c.init()
          }
      })
    }
  }
}
