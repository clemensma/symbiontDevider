#!/usr/bin/env nextflow

params.reads = '/home/cmau/pipeline/sample_data/*_{1,2}.fastq'
params.genome = '/home/cmau/pipeline/sample_data/GCA_003671365.1_ASM367136v1_cds_from_genomic.fna'


Channel.fromFilePairs( params.reads )
       .ifEmpty{error "Cannot find files"}
       .set { data }


process trimming_and_qc {

    tag "$name"

    input:
    tuple val(name), file(reads) from data

    output:
    tuple val(name), file('*.fq') into trimmed
    file '*.html' into quality

    script:
    """

    trim_galore --paired --fastqc --cores 8 ${reads[0]} ${reads[1]}

    """
}

/*trimmed.view{it.name}
quality.view{it.name}
*/

process endosymbiont_mapping {

    tag "$name"

    input:
    tuple val(name), file(reads) from trimmed
    path genome from params.genome

    output:
    file '*.sam' into mapped
    file '.command.log' into coverage_assess

    script:
    """
    bowtie2-build ${genome} wolbachia
    bowtie2-inspect -n wolbachia
    bowtie2 -x wolbachia -p 8 -1 ${reads[0]} -2 ${reads[1]} -S ${name}.sam --very-sensitive > ${name}.txt
    """

}


process read_filtering {
    
    tag "$name"

    input:
    file mapped from mapped

    output:
    file 'mapped_N*.sam' into endosym
    file 'mapped_host_*.sam' into host


    script:
    """

    samtools view -h -F 4 $mapped > mapped_${mapped}
    samtools view -h -f 4 $mapped > mapped_host_${mapped}

    """
}

process assembly {

    input:
    file mapped_endosym from endosym
    file mapped_host from host


    script:
    """

    abyss-pe np=8 name=marta2_endosym k=96 in='$mapped_endosym' B=10G H=3 kc=3 v=-v
    abyss-pe np=8 name=marta2_host k=96 in='$mapped_host' B=10G H=3 kc=3 v=-v

    """
}
/*

process coverage_size_est {

    input:
    file sample from mapped

    output:
    file '*' into quality

    script:
    """
    """

}

process assembly_quality {

    input:
    file sample from assembled

    output:
    file '*' into quality

    script:
    """
    """

}

process compression {

    input:
    file sample from assembled

    output:
    file '*.gz' into compressed

    script:
    """
    """
}

process visualise_quality {

    input:
    file sample from quality

    script:
    """
    """
}






*/
