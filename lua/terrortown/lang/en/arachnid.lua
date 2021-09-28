local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[ARACHNID.name] = "Arachnid"
L["info_popup_" .. ARACHNID.name] = [[You are an Arachnid!
You are a Traitor that can obscure bodies in webbing to make them unsearchable with your special items!]]
L["body_found_" .. ARACHNID.abbr] = "They were an Arachnid!"
L["search_role_" .. ARACHNID.abbr] = "This person was an Arachnid!"
L["target_" .. ARACHNID.name] = "Arachnid"
L["ttt2_desc_" .. ARACHNID.name] = [[The Arachnid is a Traitor role that can wrap a dead body in webbing to prevent the body from being searched.]]

L["arac_wrap_progress"] = "Time left: {time}s"
L["arac_hold_to_wrap"] = "Hold [{key}] to wrap a body in webbing to make it unsearchable!"

L["arac_wrapped"] = "This body is unsearchable! Burn the webbing in order to search the body."