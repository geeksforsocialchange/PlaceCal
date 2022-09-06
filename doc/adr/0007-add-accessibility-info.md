# Add accessibility info

- Deciders: @kimadactyl, @katjam
- Date: 2020-02-09

## Background

As part of The Trans Dimension work we conduced accessibility research to find out what would make events trans and disabled inclusive.

The result of this was a guide and a set of questions for people to answer that cover most of the bases.

We now need to integrate this into PlaceCal.

## Routes

### Solution 1.1 - use the existing textarea (chosen option)

We could simply just pre-seed the accessibility info textarea, which is currently unused, with the survey questions, and add the wider guidance to the handbook. Partners would need to spend a bit of time getting a few paras together under headings we give them.

**Pros**

- Simplest to do, very little effort
- Most flexible and allows further testing and editing, people to add or change the questions, etc

**Cons**

- Totally unstructured - hard to do direct comparisons later and no migration path
- More work for partners and coordinators as they have to prepare a para of text
- Requires people to be comfortable with visualising markdown subheadings

### Solution 1.2 - same but use ActionText

Same as above but using a rich text area.

**Pros**

- Most flexible and allows further testing and editing, people to add or change the questions, etc
- More intuitive and user friendly with headings and makes it easier to use bold, italic, headings etc

**Cons**

- Totally unstructured - hard to do direct comparisons later and no migration path
- More work for partners and coordinators as they have to prepare a para of text
- A bit more effort and we don't have ActionText set up yet. Fiddlier than just plaintext/markdown.
- Not sure how easy it is to remove ActionText features to keep the text simple
- Can't do tags/filters to show which places have what
- If we do this in one place do we need to do it in others for consistency?

### Solution 2 - create a full Q&A system

Alternatively we could build a proper Q&A system that shows which is done and not done, have standardized questions across PlaceCal sites, etc.

**Pros**

- The most robust solution going forwards esp as we can add in an interface for this for other regions
- Clean versionning of responses
- Potentially simpler and nicer UX for respondants who just have to fill in some form fields
- Will make it possible to do tags/filters

**Cons**

- Phenomenally more work. Kim has done this before but would be a job to integrate into PlaceCal. Probably a week minumum for MVP
- Structured data at this point might be forcing our hand. It's a big assumption that its not just easier for people to type out a paragraph based on our guidance
