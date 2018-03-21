#!/bin/bash

p= repo_details=()

#keywords list that need to be scanned
keywords_arr=("## Public Domain" "## License" "## Privacy" "## Contributing" "## Notices")

#Getting repository URL list
repo_list=`curl -v --silent https://api.github.com/orgs/CDCGov/repos?per_page=100 --stderr - | grep '"url":' | grep "repo" | awk '{ print $2 }' | tr -d '",'`
repourl_arr=($repo_list)

#Getting repogitory name
c=0
for i in ${repourl_arr[@]} ; do
    repo_name[c++]="${i##*/}";
done

#Function to validate file exist or not
function validate_url(){
  if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then echo "true"; else echo "false"; fi
}

#Function to check repository have particular file or not
b=0
function check_file(){
    out=`validate_url https://raw.githubusercontent.com/CDCgov/$1/master/README.md`
    if [ "$out" = false ] ; then
       echo "No"
    else
       echo "Yes"
    fi
}

function print_contributor_list() {
   contributor=`curl -v --silent https://api.github.com/repos/CDCgov/$1/contributors?per_page=500 --stderr - | grep '"login":'| tr -d '",:' | awk '{print $2 }' | head -3`
   contributor_list=($contributor)
   if ! [ ${#contributor_list[@]} -eq 0 ]; then
        echo "Below are the top 3 contributor in  repository : $1 "
        u=1
        for j in ${contributor_list[@]} ; do
            echo "Contributor $u"
            echo "  Github Username: $j "
            curl -v --silent https://api.github.com/users/"$j" --stderr - | grep -wi --color 'name\|email\|company' | tr -d '",'
            u=$((u+1));
        done
   else
      echo "There is no contributor"
   fi
}

function check_readme() {
k= missing_key=()
for keyword in ${keywords_arr[@]} ; do 
    output=`curl -s https://raw.githubusercontent.com/CDCgov/$1/master/README.md --stderr - | grep "$keyword"`
    if [ -z "$output" ]; then
       missing_key[k++]="$keyword"      
    fi
done
if ! [ ${#missing_key[@]} -eq 0 ]; then
    echo "repository: $1 don't have information about:"
    for i in ${missing_key[@]} ; do
        echo "$i"| tr -d '#'
    done
fi
}

################### Main ################
sorted_unique_repo=($(echo "${repo_name[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
for r in ${sorted_unique_repo[@]} ; do
    file_check=`check_file $r`
    if [ "$file_check" == "No" ] ; then
       echo " Repository: $r Don't have README.md file"
    else
       var=`check_readme $r`
       if ! [ -z "$var" ]; then
           echo "=================="
           check_readme $r
           print_contributor_list $r
       fi     
    fi
done       
 
 
