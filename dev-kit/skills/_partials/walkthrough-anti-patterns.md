# Walkthrough anti-patterns (shared partial)

Referenced by `walkthrough` under its "Anti-Patterns — What NOT To Do" heading.

1. **Do NOT change any code.** This skill produces documentation only.
2. **Do NOT write a file-by-file description.** The walkthrough follows the
   *data or control flow*, not the file listing. Files are referenced where
   they appear in the narrative, not enumerated independently.
3. **Do NOT guess what the code does.** Read the actual implementation of every
   function and transformation you describe. If a function is too complex to
   fully understand, say what you can verify and note the uncertainty.
4. **Do NOT skip the data model section when one applies.** For any system with
   composite keys, non-trivial hierarchies, or non-trivial join logic, the
   data model is the most important section in the walkthrough. Underinvesting
   here makes the rest of the document harder to understand.
5. **Do NOT write a user manual.** The walkthrough explains *how the system
   works internally*, not just how to run it. A reader should come away
   understanding the design decisions, not just the button presses.
6. **Do NOT describe aspirational behavior.** Document what the code *actually
   does today*, not what it should do or what the README says it does. If the
   code and README disagree, document the code's behavior and note the
   discrepancy.
7. **Do NOT omit validation checkpoints.** Inline assertions and validation
   calls are part of the system's design. They document the developer's
   assumptions and should be explained in the walkthrough.
8. **Do NOT write wall-of-text paragraphs.** Use tables for structured data
   (column schemas, input/output inventories, function summaries). Use
   numbered lists for sequential steps. Use diagrams for flow and hierarchy.
   Reserve prose for explanations that require narrative.
9. **Do NOT forget the how-to guides.** The walkthrough serves both
   understanding ("how does this work?") and action ("how do I extend it?").
   The how-to section bridges from understanding to doing.
10. **Do NOT use placeholder text.** Every section must contain real content
    derived from the actual codebase. `[TODO]`, `[TBD]`, or `[fill in later]`
    are not acceptable in the final walkthrough.
