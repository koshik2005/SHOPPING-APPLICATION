package com.hyperlocal.core.domain;

import java.io.Serializable;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public abstract class BaseDomainModel implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private String id;
    private Integer version;
}
