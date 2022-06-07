import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import System.Console.GetOpt
import Text.Printf

data Mode = Release | Dev
    deriving (Show, Eq)

data Flags = ReleaseMode
    deriving (Show, Eq)

flags = [Option "" ["release"] (NoArg $ Right ReleaseMode) "Build release"]


getPath :: Mode -> String -> String 
getPath m s = printf s ms 
    where  
        ms = case m of 
               Release -> "release" 
               Dev -> "debug"

isRelease :: [Flags] -> Bool 
isRelease = any (\s -> case s of 
                         ReleaseMode -> True 
                         )

main :: IO ()
main = shakeArgsWith shakeOptions flags $ \flags targets -> pure $ Just $ do 
    let releaseMode = if isRelease flags then Release else Dev
    let isoWant = if releaseMode /= Release then ["xargo","_build/boot/jardinii_debug.iso"] else ["xargo", "_build/boot/jardinii.iso"]
    let modePath = if releaseMode /= Release then "debug" else "release"
    let xargoArg = if releaseMode /= Release then "" else "--release"    

    if null targets then  
        want isoWant
    else 
        want targets


    phony "clean" $ do
        putInfo "Cleaning files in _build"
        removeFilesAfter "_build" ["//*"]
    
    -- HACK HACK HACK: allows for recompilation without `shake clean`
    phony "xargo" $ do 
        cmd_ "xargo build --target x86_64-unknown-linux-gnu" " " xargoArg
        removeFilesAfter "_build" ["//*.a", "//*.iso"]

    phony "run" $ do 
        putInfo "Launching qemu"
        need ["_build/boot/jardinii_debug.iso"]
        cmd_ "qemu-system-x86_64 -cdrom _build/boot/jardinii_debug.iso"


    "_build/boot/kernel" <.> "bin" %> \out -> do
        asms <- getDirectoryFiles "" ["boot//*.asm"]
        let os = ["_build" </> a -<.> "o" | a <- asms]
        need os
        need ["_build" </> modePath </> "libjardinii.a"]
        cmd_ "ld.lld -n -o" [out] "-T boot/linker.ld" os ("_build" </> modePath </> "libjardinii.a")

    "_build/boot//*.o" %> \out -> do
        let a = dropDirectory1 $ out -<.> "asm"
        cmd_ "nasm -f elf64" [a] "-o" [out]
    
    "_build/*/libjardinii.a" %> \out -> do 
        need ["target" </> "x86_64-unknown-linux-gnu" </> modePath </> "libjardinii.a"]
        copyFile' ("target/x86_64-unknown-linux-gnu/" </> modePath </> "libjardinii.a") ("_build/" </> modePath </> "libjardinii.a")

    "target/x86_64-unknown-linux-gnu/*/libjardinii.a" %> \out -> do 
        cmd_ "xargo build --target x86_64-unknown-linux-gnu" " " xargoArg

    "_build/boot/jardinii*.iso" %> \out -> do 
        need ["_build/boot/kernel.bin"]
        copyFile' "boot/grub.cfg" "_build/boot/isofiles/boot/grub/grub.cfg"
        copyFile' "_build/boot/kernel.bin" "_build/boot/isofiles/boot/kernel.bin"
        cmd_ "grub-mkrescue -o" [out] "_build/boot/isofiles"

