import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Hybrid brand classification: Vision + regex anchors first; LLM only for missing fuzzy fields.
enum IntelligentBrandClassifier {
    /// Fast rules-only brand guess for the pre-extraction confirmation step.
    static func suggestBrand(_ ticket: ExtractedTicket) -> ClassificationResult {
        BrandClassifier.classify(ticket)
    }

    static func classify(_ ticket: ExtractedTicket, forcedTemplateId: String? = nil) async -> ClassificationResult {
        // Step A+B: Vision ticket already extracted; BrandClassifier / forced extract locks anchors.
        let rules: ClassificationResult
        if let forced = forcedTemplateId?.trimmingCharacters(in: .whitespacesAndNewlines), !forced.isEmpty {
            rules = BrandPassRegistry.extract(for: forced, ticket: ticket)
        } else {
            rules = BrandClassifier.classify(ticket)
        }

        var fields = rules.fields
        HybridPassFill.lockAnchors(into: &fields, ticket: ticket, rules: rules)

        // Step C: fill only empty fuzzy keys (event, restaurant, …) — never QR/PNR/booking IDs.
        fields = await HybridPassFill.fillMissingFuzzy(
            templateId: rules.templateId,
            fields: fields,
            ticket: ticket
        )
        HybridPassFill.lockAnchors(into: &fields, ticket: ticket, rules: rules)

        var result = ClassificationResult(
            templateId: rules.templateId,
            displayName: rules.displayName,
            confidence: rules.confidence,
            fields: fields,
            stationIds: rules.stationIds,
            relevantDateISO8601: rules.relevantDateISO8601,
            rationale: rules.rationale.isEmpty
                ? "Hybrid: Vision/regex anchors + targeted fuzzy fill"
                : rules.rationale,
            needsManualBrandPick: rules.needsManualBrandPick,
            extracted: ticket,
            createdAt: Date()
        )
        if let forced = forcedTemplateId?.trimmingCharacters(in: .whitespacesAndNewlines), !forced.isEmpty {
            result.templateId = forced
            result.needsManualBrandPick = false
            result.confidence = max(result.confidence, 0.92)
            if result.displayName.isEmpty || result.displayName == rules.templateId {
                result.displayName = BrandPassRegistry.friendlyName(for: forced)
            }
        }
        return enrich(result)
    }

    /// Legacy merge kept for tests / share-extension callers that still produce AI drafts.
    static func merge(ai: ClassificationResult, rules: ClassificationResult) -> ClassificationResult {
        let handler = BrandPassRegistry.handler(for: rules.templateId)
        var preferRules = handler?.prefersRules(over: ai, rules: rules) == true
        let theatreIds: Set<String> = ["bookmyshow", "district"]
        let diningIds: Set<String> = ["easydiner", "zomato-dineout", "swiggy-dineout"]
        if !preferRules, diningIds.contains(rules.templateId), theatreIds.contains(ai.templateId), rules.confidence >= 0.7 {
            preferRules = true
        }

        let templateId: String
        if preferRules {
            templateId = rules.templateId
        } else if !ai.templateId.isEmpty {
            templateId = ai.templateId
        } else {
            templateId = rules.templateId
        }

        var fields = rules.fields
        let blocked = preferRules
            ? ["event", "venue", "seat", "origin", "destination", "pnr", "train"]
            : []
        for (key, value) in ai.fields {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if blocked.contains(key) { continue }
            if HybridPassFill.anchorKeys.contains(key) { continue }
            let existing = fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if existing.isEmpty || !preferRules {
                fields[key] = trimmed
            }
        }
        HybridPassFill.lockAnchors(into: &fields, ticket: rules.extracted.qrPayload != nil ? rules.extracted : ai.extracted, rules: rules)

        if preferRules, rules.templateId == "easydiner" || rules.templateId.contains("dineout") {
            let restaurant = fields["restaurant"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if restaurant.isEmpty,
               let event = ai.fields["event"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !event.isEmpty, !event.lowercased().hasPrefix("dee ") {
                fields["restaurant"] = event
            }
        }

        let fallbackTitle = fields["vehicle"] ?? fields["restaurant"] ?? fields["event"] ?? rules.templateId
        let displayName: String
        if preferRules {
            displayName = rules.displayName.isEmpty ? fallbackTitle : rules.displayName
        } else if ai.displayName.isEmpty || ai.displayName == templateId {
            displayName = rules.displayName.isEmpty ? templateId : rules.displayName
        } else {
            displayName = ai.displayName
        }

        var result = ClassificationResult(
            templateId: templateId,
            displayName: displayName,
            confidence: max(ai.confidence, rules.confidence),
            fields: fields,
            stationIds: preferRules && rules.templateId == "zoomcar"
                ? []
                : (ai.stationIds.isEmpty ? rules.stationIds : ai.stationIds),
            relevantDateISO8601: preferRules
                ? (rules.relevantDateISO8601 ?? ai.relevantDateISO8601)
                : (ai.relevantDateISO8601 ?? rules.relevantDateISO8601),
            rationale: preferRules
                ? rules.rationale
                : (ai.rationale.isEmpty ? rules.rationale : ai.rationale),
            needsManualBrandPick: templateId.isEmpty,
            extracted: ai.extracted,
            createdAt: Date()
        )
        return enrich(result)
    }

    static func enrich(_ classification: ClassificationResult) -> ClassificationResult {
        BrandPassRegistry.enrich(classification)
    }
}
