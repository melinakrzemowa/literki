#!/bin/zsh
# Checks how a system voice reads single letters, without needing to hear it.
#
#     tools/check_voices.sh Zosia
#     tools/check_voices.sh Samantha
#
# `say` is deterministic, so identical audio means identical pronunciation.
# Each letter is synthesised next to the written-out name it should be read
# as; a matching checksum proves the voice says the name.
#
# Duration alone does NOT prove this — "el" and "eł" take the same time to
# say, which once led to the wrong conclusion that Polish voices ignore
# diacritics. They do not.
#
# macOS only; `say` is Apple's. The game itself uses Godot's DisplayServer
# text-to-speech, which draws on the same voices.

voice="${1:-Zosia}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

hash_of() {
	say -v "$voice" -o "$work/out.aiff" "$1" 2>/dev/null || return 1
	md5 -q "$work/out.aiff"
}

compare() {
	local letter="$1" expected="$2"
	local a b
	a="$(hash_of "$letter")" || { printf "  %-4s could not synthesise\n" "$letter"; return; }
	b="$(hash_of "$expected")"
	if [[ "$a" == "$b" ]]; then
		printf "  %-4s reads as \"%s\"\n" "$letter" "$expected"
	else
		printf "  %-4s does NOT read as \"%s\"\n" "$letter" "$expected"
	fi
}

echo "voice: $voice"

case "$voice" in
	Zosia)
		for pair in "a:a" "ą:ą" "b:be" "c:ce" "ć:cie" "d:de" "e:e" "ę:ę" "f:ef" \
			"g:gie" "h:ha" "i:i" "j:jot" "k:ka" "l:el" "ł:eł" "m:em" "n:en" \
			"ń:eń" "o:o" "p:pe" "r:er" "s:es" "ś:eś" "t:te" "u:u" "w:wu" \
			"y:igrek" "z:zet" "ź:ziet" "ż:żet"; do
			compare "${pair%%:*}" "${pair##*:}"
		done
		echo "  (ó is read as something longer than \"o\" — listen to it yourself)"
		;;
	*)
		for pair in "b:bee" "c:see" "d:dee" "e:ee" "f:eff" "g:gee" "h:aitch" \
			"j:jay" "k:kay" "l:el" "m:em" "n:en" "p:pee" "q:cue" "r:ar" \
			"s:ess" "t:tee" "v:vee" "x:ex" "y:why" "z:zee"; do
			compare "${pair%%:*}" "${pair##*:}"
		done
		;;
esac
