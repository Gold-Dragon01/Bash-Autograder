#!/usr/bin/bash

readonly TIMEOUT_SECONDS=10

#filename=$2
#echo $filename
usage() {
    echo "Usage: $0 -f <conditions_file>"
    exit 1
}

while getopts "f:" opt; do
    case $opt in
        f) filename="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "$filename" ]; then
    usage
fi


mapfile -t conditions < "$filename"

# Input File Validation

useArchive="${conditions[0]}"
#echo "$useArchive"
if [[ "$useArchive" != "true" && "$useArchive" != "false" ]]; then
    echo "Use Archive condition is not valid"
    exit 1    
fi

allowedArchives="${conditions[1]}"
#echo "$allowedArchives"
if [ "$useArchive" = "true" ];then
    for val in $allowedArchives
    do
        #echo $val
        if [[ "$val" != "zip" && "$val" != "rar" && "$val" != "tar" ]];then
            echo "Allowed archives are not in known format"
            exit 1
        fi
    done
fi

allowedLangs="${conditions[2]}"
#echo "$allowedLangs"
for val in $allowedLangs
do
    #echo $val
    if [[ "$val" != "c" && "$val" != "cpp" && "$val" != "python" && "$val" != "sh" ]];then
        echo "Allowed Languages are not known"
        exit 1
    fi
done

totalMarks=${conditions[3]}
if ! [[ $totalMarks =~ ^[0-9]+$ ]]; then
    echo "Total Marks is not a number"
    exit 1
fi

outputPenalty=${conditions[4]}
if ! [[ $outputPenalty =~ ^[0-9]+$ ]]; then
    echo "Penalty for wrong output is not a number"
    exit 1
fi  

workingDirectory=${conditions[5]}
#echo "$workingDirectory"
if ! [ -d "$workingDirectory" ];then
    echo "Given working directory doesn't exist or not a directory"
    exit 1
fi

range=${conditions[6]}
read firstId lastId <<< "$range"
if ! [[ $firstId =~ ^[0-9]+$ ]]; then
    echo "FirstID is not a number"
    exit 1
elif ! [[ $lastId =~ ^[0-9]+$ ]]; then
    echo "LastID is not a number"
    exit 1
fi

#echo $firstId, $lastId

expectedOutputFile=${conditions[7]}
if ! [ -f "$expectedOutputFile" ];then
    echo "Given expected output file path is not correct"
    exit 1
fi

submissionPenalty=${conditions[8]}
if ! [[ $submissionPenalty =~ ^[0-9]+$ ]]; then
    echo "Penalty for not following submission guideline is not a number"
    exit 1
fi   

plagiarismFile=${conditions[9]}
if ! [ -f "$plagiarismFile" ];then
    echo "Given plagiarism file path is not correct"
    exit 1
fi

plagiarismPenalty=${conditions[10]}
if ! [[ $plagiarismPenalty =~ ^[0-9]+$ ]]; then
    echo "Penalty for plagiarism is not a number"
    exit 1
fi

echo "Checking File Done"

cd "$workingDirectory"
mkdir -p issues checked
marksFile="marks.csv"
echo  "id, marks, marks_deducted, total_marks, remarks" > "$marksFile"
#cat "$marksFile"
mapfile -t plagiarised < "$plagiarismFile"

for ((id=firstId;id<=lastId;id++))
do
    marks=$totalMarks
    marks_deducted=0
    remarks=""
    folderCreated=0
    foundSubmission=0
    for item in *
    do
        if [[ "$item" == ${id}* ]]; then
            foundSubmission=1
            if [ -d "$item" ];then
                folderCreated=1
                marks_deducted=$(($marks_deducted+$submissionPenalty))
                remarks+="issue case #1 "
            elif [ -f "$item" ];then
                if [[ "$useArchive" == "true" ]];then
                    for val in $allowedArchives
                    do
                        if [[ "$item" == "${id}.${val}" ]];then
                            folderCreated=1
                            before=$(ls -d */)
                            if [[ "$val" == "zip" ]];then
                                unzip "${id}.${val}"
                            elif [[ "$val" == "rar" ]];then
                                unrar x "${id}.${val}"
                            elif [[ "$val" == "tar" ]];then 
                                tar -xf "${id}.${val}"
                            fi
                            after=$(ls -d */)
                            newDir=$(comm -13 <(echo "$before") <(echo "$after"))
                            if [[ "$newDir" != "${id}/" ]];then
                                marks_deducted=$(($marks_deducted+$submissionPenalty))
                                remarks+="issue case #4 "
                                mv "$newDir" "${id}/"
                            fi
                            break
                        fi            
                    done
                elif [[ "$useArchive" == "false" ]];then
                    folderCreated=1
                    mkdir "$id"
                    mv "$item" "${id}/"  
                fi        
            fi
            if [ "$folderCreated" -eq 1 ];then
                #echo "newly created directory is: " "$newDir"    
                cd "${id}/"
                file=$(echo *)
                ok=0
                for val in $allowedLangs
                do
                    if [[ "$val" == "python" ]];then
                        val="py"
                    fi    
                    if [[ "$file" == "${id}.${val}" ]];then
                        ok=1
                        chmod +x "$file"
                        if [[ "$val" == "c" ]];then
                            if gcc "$file" 2>/dev/null;then
                                timeout "${TIMEOUT_SECONDS}s" ./a.out > "${id}_output.txt" 2>/dev/null
                                if [ $? -eq 124];then
                                    remarks+="TLE "
                                fi
                            else
                                remarks+="Compilation_Error "
                                ok=0
                            fi
                        elif [[ "$val" == "cpp" ]];then
                            if g++ "$file" 2>/dev/null;then
                                timeout "${TIMEOUT_SECONDS}s" ./a.out > "${id}_output.txt" 2>/dev/null
                                if [ $? -eq 124 ]; then
                                    remarks+="TLE "
                                fi
                            else
                                remarks+="compilation_error "
                                ok=0
                            fi
                        elif [[ "$val" == "sh" ]];then
                            timeout "${TIMEOUT_SECONDS}s" bash "$file" > "${id}_output.txt" 2>/dev/null
                            if [ $? -eq 124 ];then
                                remarks+="TLE "
                            fi
                        elif [[ "$val" == "py" ]];then
                            timeout "${TIMEOUT_SECONDS}s" python3 "$file" > "${id}_output.txt" 2>/dev/null
                            if [ $? -eq 124 ];then
                                remarks+="TLE "
                            fi
                        fi
                        break
                    fi                      
                done 
                if [ $ok -eq 0 ];then
                    marks=0
                    marks_deducted=$(($marks_deducted+$submissionPenalty))
                    remarks+="issue case #3 "
                    cd ..   
                    mv "${id}/" "issues/"
                else
                    mismatch1=$(comm -23 <(sort "${id}_output.txt") <(sort "$expectedOutputFile")| wc -l)
                    mismatch2=$(comm -13 <(sort "${id}_output.txt") <(sort "$expectedOutputFile")| wc -l)
                    if [ $mismatch1 -gt $mismatch2 ];then
                        mismatch=$mismatch1
                    else mismatch=$mismatch2
                    fi    
                    marks=$(($marks - $mismatch*$outputPenalty))
                    if [ $marks -lt 0 ];then
                        marks=0
                    fi
                    cd ..
                    mv "${id}/" "checked/"
                fi
            else
                marks=0
                marks_deducted=$(($marks_deducted+$submissionPenalty))
                remarks+="issue case #2 "    
            fi
            break                          
        fi
    done
    if [ $foundSubmission -eq 0 ];then
        remarks+="missing submission"
        marks=0
    fi
    chor=0
    for val in ${plagiarised[@]}
    do
        if [[ "$id" == "$val" ]];then
            chor=1
            break
        fi
    done
    if [ $chor -eq 1 ];then
        total_marks=$((-(plagiarismPenalty*totalMarks)/100))
        remarks+="plagiarism detected"
    else        
        total_marks=$(($marks-$marks_deducted))
    fi    
    echo  ""$id", "$marks", "$marks_deducted", "$total_marks", "$remarks"" >> "$marksFile"    
done
