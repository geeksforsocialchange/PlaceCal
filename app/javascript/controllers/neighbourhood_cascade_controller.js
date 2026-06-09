import { Controller } from "@hotwired/stimulus";

// Cascading neighbourhood filter for the directory.
//
// Drills the geographic hierarchy (region > county > district > ward) using a
// preloaded tree — no AJAX. Each select shows the children of the level above;
// the hidden `neighbourhood` field always carries the deepest selected id, so
// stopping at any level filters that whole subtree.
export default class extends Controller {
	static targets = ["field", "selects"];
	static values = {
		tree: Array,
		selected: String,
		label: { type: String, default: "Neighbourhood" },
	};

	connect() {
		// Path of selected nodes from the root down to the deepest selection.
		this.path = this.findPath(this.treeValue, this.selectedValue);
		this.render({ initial: true });
	}

	// Rebuild one select per level along the current path, plus the next empty
	// level so the user can keep drilling down.
	render({ initial = false } = {}) {
		this.selectsTarget.innerHTML = "";
		let nodes = this.treeValue;
		for (let depth = 0; nodes && nodes.length > 0; depth++) {
			const selected = this.path[depth];
			this.appendSelect(nodes, selected, depth);
			if (!selected) break;
			nodes = selected.children || [];
		}
		this.updateField(initial);
	}

	appendSelect(nodes, selected, depth) {
		const wrapper = document.createElement("div");
		wrapper.className = "min-w-0 flex-1";

		const select = document.createElement("select");
		select.className =
			"w-full sm:w-56 border-2 border-rules rounded-sm px-4 py-2 text-sm bg-background text-foreground cursor-pointer hover:border-foreground transition-colors";
		select.dataset.depth = depth;
		// Accessible name: the dynamically-created selects aren't tied to the
		// visible label, so give each one an explicit aria-label.
		select.setAttribute(
			"aria-label",
			depth === 0
				? this.labelValue
				: `${this.labelValue} within ${this.path[depth - 1].name}`,
		);
		// Bind directly rather than via data-action: these selects are created
		// dynamically and Stimulus's action observer binds asynchronously, which
		// can miss a fast first interaction. A direct listener is bound immediately.
		select.addEventListener("change", (event) => this.change(event));

		// Parent-relative placeholder, so messy/inconsistent unit labels in the
		// source data never produce a wrong level name ("All districts" over a
		// list of counties). Picking it filters by the parent's whole subtree.
		const placeholder = document.createElement("option");
		placeholder.value = "";
		placeholder.textContent =
			depth === 0
				? "All neighbourhoods"
				: `All of ${this.path[depth - 1].name}`;
		select.appendChild(placeholder);

		nodes.forEach((node) => {
			const option = document.createElement("option");
			option.value = String(node.id);
			option.textContent = node.count
				? `${node.name} (${node.count})`
				: node.name;
			if (selected && String(node.id) === String(selected.id)) {
				option.selected = true;
			}
			select.appendChild(option);
		});

		wrapper.appendChild(select);
		this.selectsTarget.appendChild(wrapper);
	}

	change(event) {
		const depth = Number(event.target.dataset.depth);
		const value = event.target.value;

		// Drop this level and anything below it, then re-add the new selection.
		this.path = this.path.slice(0, depth);
		if (value) {
			const node = this.nodesAtDepth(depth).find(
				(n) => String(n.id) === String(value),
			);
			if (node) this.path.push(node);
		}
		this.render();
	}

	// The list of nodes shown by the select at the given depth.
	nodesAtDepth(depth) {
		let nodes = this.treeValue;
		for (let d = 0; d < depth; d++) {
			nodes = this.path[d] ? this.path[d].children || [] : [];
		}
		return nodes;
	}

	updateField(initial = false) {
		const deepest = this.path[this.path.length - 1];
		if (deepest) {
			this.fieldTarget.value = String(deepest.id);
		} else if (!initial) {
			// User cleared the selection. On initial render we leave the
			// server-rendered value untouched, so a selected neighbourhood that
			// isn't in the preloaded tree (e.g. one with no partners) survives.
			this.fieldTarget.value = "";
		}
	}

	// Walk the tree to the node with the given id, returning the chain of nodes
	// from the root down to it (empty when nothing is selected or not found).
	findPath(nodes, targetId) {
		if (!targetId) return [];
		for (const node of nodes) {
			if (String(node.id) === String(targetId)) return [node];
			const childPath = this.findPath(node.children || [], targetId);
			if (childPath.length) return [node, ...childPath];
		}
		return [];
	}
}
