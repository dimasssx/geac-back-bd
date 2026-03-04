package br.com.geac.backend.Domain.Enums;

public enum DaysBeforeNotify {
    ONE_DAY_BEFORE(1),
    ONE_WEEK_BEFORE(7);

    private final int days;

    DaysBeforeNotify(int days) {
        this.days = days;
    }
    public int getDays() {
        return days;
    }
}
