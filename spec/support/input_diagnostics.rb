# frozen_string_literal: true

# On a failed system spec, records whether the browser still accepts real
# keyboard and mouse input, to pin down the flakes tracked in #3341.
module InputDiagnostics
  PAGE_STATE_JS = <<~JS
    (() => {
      const active = document.activeElement;
      const checkedTab = document.querySelector("input.tab:checked");
      return {
        url: location.href,
        readyState: document.readyState,
        visibilityState: document.visibilityState,
        hasFocus: document.hasFocus(),
        activeElement: active ? `${active.tagName}#${active.id}[name=${active.getAttribute("name")}]` : null,
        checkedTab: checkedTab ? checkedTab.dataset.hash : null,
        formTabsConnected: !!document.querySelector("[data-form-tabs-connected]"),
        saveBarConnected: !!document.querySelector("[data-save-bar-connected]"),
        openDialogs: document.querySelectorAll("dialog[open]").length,
        inertElements: document.querySelectorAll("[inert]").length,
        paints: performance.getEntriesByType("paint").map((p) => `${p.name}@${Math.round(p.startTime)}ms`),
        msSinceNavigation: Math.round(performance.now())
      };
    })()
  JS

  # A confirm() would block the probes below, so it is stubbed out first.
  ADD_PROBES_JS = <<~JS
    window.confirm = () => true;
    const style = "position:fixed;top:0;left:0;z-index:2147483647;width:80px;height:30px";
    const button = Object.assign(document.createElement("button"), { id: "input-probe-button", type: "button" });
    button.style.cssText = style;
    button.addEventListener("click", () => { button.dataset.clicked = "true"; });
    const input = Object.assign(document.createElement("input"), { id: "input-probe-text" });
    input.style.cssText = `${style};top:30px`;
    document.body.append(button, input);
  JS

  JS_TAB_CLICK_JS = <<~JS
    (() => {
      const tab = document.querySelector("input.tab:not(:checked)");
      if (!tab) return null;
      tab.click();
      return tab.checked;
    })()
  JS

  module_function

  def report(page, example)
    result = { example: example.location, windows: page.driver.browser.window_handles.size }
    result[:page] = page.evaluate_script(PAGE_STATE_JS)
    result[:console] = page.driver.browser.logs.get(:browser).last(10).map(&:message)
    result.merge!(probes(page))
  rescue StandardError => e
    result = (result || {}).merge(error: "#{e.class}: #{e.message}".truncate(300))
  ensure
    warn "[input-diagnostics] #{result.to_json}"
  end

  def probes(page)
    page.execute_script(ADD_PROBES_JS)
    page.find_by_id("input-probe-button").click
    page.find_by_id("input-probe-text").send_keys("probe")
    native_tab = page.first("input.tab:not(:checked)", minimum: 0)
    native_tab&.click

    {
      native_click_works: page.evaluate_script("document.getElementById('input-probe-button').dataset.clicked === 'true'"),
      native_typing_works: page.evaluate_script("document.getElementById('input-probe-text').value") == "probe",
      native_tab_click_works: native_tab && page.evaluate_script("arguments[0].checked", native_tab),
      js_tab_click_works: page.evaluate_script(JS_TAB_CLICK_JS)
    }
  end
end
