"""Adds ios/Runner/PrivacyInfo.xcprivacy to the Runner target's resources (idempotent)."""
import sys
p = sys.argv[1] if len(sys.argv) > 1 else "ios/Runner.xcodeproj/project.pbxproj"
s = open(p).read()
if "PrivacyInfo.xcprivacy" in s:
    print("already added"); sys.exit(0)
FREF, BFILE = "F0F0A0011CF9000F00FC0001", "F0F0A0021CF9000F00FC0001"
s = s.replace("/* End PBXBuildFile section */",
    f"\t\t{BFILE} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {FREF} /* PrivacyInfo.xcprivacy */; }};\n/* End PBXBuildFile section */", 1)
s = s.replace("/* End PBXFileReference section */",
    f"\t\t{FREF} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = PrivacyInfo.xcprivacy; sourceTree = \"<group>\"; }};\n/* End PBXFileReference section */", 1)
# Runner group: add next to Info.plist
anchor = "/* Info.plist */,"
i = s.find(anchor, s.find("/* Runner */ = {\n\t\t\tisa = PBXGroup;"))
s = s[:i + len(anchor)] + f"\n\t\t\t\t{FREF} /* PrivacyInfo.xcprivacy */," + s[i + len(anchor):]
# Runner resources phase
a2 = "/* LaunchScreen.storyboard in Resources */,"
j = s.find(a2)
s = s[:j + len(a2)] + f"\n\t\t\t\t{BFILE} /* PrivacyInfo.xcprivacy in Resources */," + s[j + len(a2):]
open(p, "w").write(s)
print("added")
