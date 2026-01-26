// Load all Stimulus controllers via importmap
// This uses eagerLoadControllersFrom which properly resolves controller paths
// through the importmap, ensuring digested asset URLs work correctly

import { application } from "./application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
